# nix-darwin-config

All steps needed to deploy the provided Nix configuration files are accessible through the repository's `Makefile`. Note that some commands may need to be run with `sudo`.

## Setup

This repository uses Determinate Systems' downstream distribution of Nix. To install Determinate Nix, run

```bash
make setup
```

## Build

To apply changes defined in `flake.nix`, run

```bash
make build
```

## Uninstall

To uninstall Determinate Nix, run

```bash
make uninstall
```

