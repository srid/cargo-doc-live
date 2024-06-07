{
  inputs = {
    nixpkgs = { };
    flake-parts = { };
    cargo-doc-live = { };
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.process-compose-flake.flakeModule
        inputs.cargo-doc-live.flakeModule
      ];
      perSystem = { config, self', pkgs, ... }: {
        devShells.test = pkgs.mkShell {
          imports = [
            inputs.process-compose-flake.flakeModule
            inputs.cargo-doc-live.flakeModule
          ];

          packages = [
            config.process-compose.cargo-doc-live.outputs.package
          ];
        };

        # Our test
        checks.test =
          pkgs.runCommandNoCC "test"
            {
              nativeBuildInputs = with pkgs; [
                which
              ] ++ self'.devShells.test.nativeBuildInputs;
            }
            ''
              (
              set -x
              echo "Testing ..."

              which cargo-doc-live || \
                (echo "cargo-doc-live should be in devshell"; exit 2)

              touch $out
              )
            '';
      };
    };
}
