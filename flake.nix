{
  description = "A `flake-parts` module provinding live server for `cargo doc`";
  outputs = { ... }: {
    flakeModule = ./flake-module.nix;
  };
}
