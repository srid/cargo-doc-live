# cargo-doc-live

A [flake module](https://nixos.asia/en/flake-parts) to provide a live server version of `cargo doc` ― edit Rust code, and see the docs view in your web browser update automatically.

https://github.com/srid/cargo-doc-live/assets/3998/37378858-dda1-40fb-8f6a-f76dc857a661

## Getting Started

Full example: https://github.com/srid/rust-nix-template

Add the following flake inputs,

```nix
process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
cargo-doc-live.url = "github:srid/cargo-doc-live";
```

Import the relevant flake-parts modules,

```nix
imports = [
  inputs.process-compose-flake.flakeModule
  inputs.cargo-doc-live.flakeModule
];
```

Add the following to the `packages` of your devShell

```nix
packages = [
  config.process-compose.cargo-doc-live.outputs.package
];
```

This will make the `cargo-doc-live` command available in your shell.

