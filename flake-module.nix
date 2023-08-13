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
              in
              {
                tui = false;
                port = 0; # process-compose exits silently if port is in use; default is 8080.
                settings.processes = {
                  cargo-doc.command = builtins.toString (pkgs.writeShellScript "cargo-doc" ''
                    run-cargo-doc() {
                      cargo doc --document-private-items --all-features
                      ${browser-sync} reload --port ${port}  # Trigger reload in browser
                    }; export -f run-cargo-doc
                    cargo watch -s run-cargo-doc
                  '');
                  browser-sync.command = ''
                    ${browser-sync} start --port ${port} --ss target/doc -s target/doc \
                      --startPath /${cfg.crateName}/
                  '';
                };
              };
          };
        });
  };
}
