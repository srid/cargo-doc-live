{
  description = "A `flake-parts` module provinding live server for `cargo doc`";
  outputs = { ... }: {
    flakeModule = ./flake-module.nix;

    # https://github.com/srid/nixci
    nixci.default = let overrideInputs = { cargo-doc-live = ./.; }; in {
      test = {
        inherit overrideInputs;
        dir = "test";
      };
    };
  };
}
