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
                default = builtins.replaceStrings [ "-" ] [ "_" ]
                  ((lib.trivial.importTOML (self + /Cargo.toml)).package.name);
                defaultText = "The crate name is derived from the Cargo.toml file";
              };
            };
          };

        in
        {
          options.cargo-doc-live = lib.mkOption {
            type = mainSubmodule;
            description = lib.mdDoc ''
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
              in
              {
                tui = false;
                port = 0; # process-compose exits silently if port is in use; default is 8080.
                settings.processes = {
                  cargo-doc = {
                    command = builtins.toString (pkgs.writeShellScript "cargo-doc" ''
                      run-cargo-doc() {
                        ${cargo} doc --document-private-items --all-features
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
