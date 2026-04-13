# nix-darwin-config

This repository contains Nix configuration files managed via a `Makefile`. All
deployment steps are automated.

> **Note:** Some commands may require `sudo` privileges.

## Setup

This configuration uses the [Determinate Systems](https://determinate.systems/)
distribution of Nix.

1. **Install Nix:**

    ```bash
    make setup
    ```

2. **Unlock secrets:**

    ```bash
    git-crypt unlock
    ```

3. **Build:**

    ```bash
    make build CONFIG=<CONFIG_NAME>
    ```

## Adding a New Machine

1. Add a new file `user-data/<CONFIG_NAME>.nix`:

    ```nix
    {
      user = "your_username";
      uid = 1000; # Replace with your actual UID
      gitUserName = "Your Name";
      gitUserEmail = "your.email@example.com";
    }
    ```

2. Add an entry in `flake.nix`:

    ```nix
    darwinConfigurations."<CONFIG_NAME>" = mkSystem (import ./user-data/<CONFIG_NAME>.nix);
    ```

3. Commit both files (user-data will be encrypted automatically by git-crypt).

## Build

Apply the configuration defined in `flake.nix`. Also generates `versions.csv`
with installed package versions for nixpkgs, brews, casks, and mas apps:

```bash
make build CONFIG=<CONFIG_NAME>
```

## Uninstall

Remove Determinate Nix and related components:

```bash
make uninstall
```

## Development Utilities

### Format Code

Format all Markdown, JSON, Bash, and Nix files in the current directory:

```bash
make format
```

### Static Analysis

Run static checks on scripts (ShellCheck for Bash, syntax check for JSON):

```bash
make check
```

## Notes

- `versions.csv` is not a lockfile — versions may vary machine to machine.
  It provides a rough reference of what versions were present on a working
  system.

## Acknowledgements

Code was generated with AI assistance.
