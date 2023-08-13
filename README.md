# cargo-doc-live

Flake module to provide a live server version of `cargo doc` ― edit Rust code, and see the docs view in your web browser update automatically.

https://github.com/srid/cargo-doc-live/assets/3998/37378858-dda1-40fb-8f6a-f76dc857a661

## Getting Started

Example use: https://github.com/juspay/nix-browser/commit/a97ca7cd5e9be6f188368fc8580c4b652c272cec

Import this along with the process-compose-flake module,

```nix
imports = [
  inputs.process-compose-flake.flakeModule
  inputs.cargo-doc-live.flakeModule
];
```

Add the following to the `nativeBuildInputs` of your devShell

```nix
nativeBuildInputs = [
  config.process-compose.cargo-doc-live.outputs.package
];
```

This will make the `cargo-doc-live` command available in your shell.

