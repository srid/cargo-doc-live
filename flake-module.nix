{ self, lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    mkOption
    types;
in
{
  options = {
    perSystem = mkPerSystemOption
      ({ config, self', inputs', pkgs, system, ... }:
        let
          cargoToml = lib.trivial.importTOML (self + /Cargo.toml);
          mainSubmodule = types.submodule {
            options = {
              port = mkOption {
                type = types.int;
                description = "The port for 'cargo doc'";
                default = 8008;
              };
              crateName = mkOption {
                type = types.str;
                description = "The crate to use when opening docs in browser";
                default = builtins.replaceStrings [ "-" ] [ "_" ] (cargoToml.package.name);
                defaultText = "The crate name is derived from the Cargo.toml file";
              };
              rustDoc = mkOption {
                type = types.submodule {
                  options = {
                    allFeatures = mkOption {
                      type = types.bool;
                      description = "The --all-features to use when running cargo doc cli";
                      default = if lib.hasAttrByPath [ "package" "metadata" "docs" "rs" "all-features" ] cargoToml then cargoToml.package.metadata.docs.rs.all-features else false;
                    };
                    extraArgs = mkOption {
                      type = types.listOf types.str;
                      description = "The extra args to use when running cargo doc cli";
                      default = if lib.hasAttrByPath [ "package" "metadata" "docs" "rs" "rustdoc-args" ] cargoToml then cargoToml.package.metadata.docs.rs.rustdoc-args else [ ];
                    };
                  };
                };
                default = { };
              };
            };
          };
        in
        {
          options.cargo-doc-live = lib.mkOption {
            type = mainSubmodule;
            description = ''
              cargo-doc-live module options
            '';
            default = { };
          };

          config = {
            process-compose.cargo-doc-live =
              let
                cfg = config.cargo-doc-live;
                port = builtins.toString cfg.port;
                browser-sync = lib.getExe pkgs.nodePackages.browser-sync;
                cargo-watch = lib.getExe pkgs.cargo-watch;
                cargo = lib.getExe pkgs.cargo;
                rustDocArgs = [
                  (lib.optionalString cfg.rustDoc.allFeatures "--all-features")
                ] ++ cfg.rustDoc.extraArgs;
              in
              {
                tui = false;
                settings.processes = {
                  cargo-doc = {
                    command = builtins.toString (pkgs.writeShellScript "cargo-doc" ''
                      run-cargo-doc() {
                        ${cargo} doc ${builtins.concatStringsSep " " rustDocArgs}
                        ${browser-sync} reload --port ${port}  # Trigger reload in browser
                      }; export -f run-cargo-doc
                      ${cargo-watch} watch -s run-cargo-doc
                    '');
                    readiness_probe = {
                      period_seconds = 1;
                      failure_threshold = 100000; # 'cargo doc' can take quite a while.
                      exec.command = ''
                        # Wait for the first 'cargo doc' to have completed.
                        # We'll use this state to block browser-sync from starting
                        # and opening the URL in the browser.
                        ls target/doc/${cfg.crateName}/index.html
                      '';
                    };
                  };
                  browser-sync = {
                    command = ''
                      ${browser-sync} start --port ${port} --ss target/doc -s target/doc \
                        --startPath /${cfg.crateName}/
                    '';
                    depends_on."cargo-doc".condition = "process_healthy";
                  };
                };
              };
          };
        });
  };
}
