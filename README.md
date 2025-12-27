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

2. **Configure User Data:**

    Create a file named `user-data.nix` in the root directory with your user details:

    ```nix
    {
      user = "your_username";
      uid = 1000; # Replace with your actual UID
      gitUserName = "Your Name";
      gitUserEmail = "your.email@example.com";
    }
    ```

## Build

Apply the configuration defined in `flake.nix`:

```bash
make build
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

## Acknowledgements

Code was generated with AI assistance.
