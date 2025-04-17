# nix-darwin-config

All steps needed to deploy the provided Nix configuration files are accessible
through the repository's `Makefile`. Note that some commands may need to be run
with `sudo`.

## Setup

This repository uses Determinate Systems' downstream distribution of Nix. To
install Determinate Nix, run

```bash
make setup
```

To provide user related data, create a file called `user-data.nix` of the form

```nix
{
  user = "${USER}";
  uid = ${USER_ID};  # No quotations needed
  gitUserName = "${GIT_USER_NAME}";
  gitUserEmail = "${GIT_USER_EMAIL}";
}
```

with the right-hand side values specified.

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

## Format

To format all Nix files in the current directory in place, run

```bash
make format
```
