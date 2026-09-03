# nix-darwin-config

This repository contains Nix configuration files managed via a `Makefile`. All
deployment steps are automated.

> [!NOTE]
> Developed with AI assistance.

## Design Principles

- **Not fully pure.** Nix flakes can build a system purely, meaning every
  input is pinned and the same files always produce the same machine
  configuration. This repository relaxes that guarantee. Homebrew and Mac App
  Store apps are installed by their own tools and their versions are free to
  drift.
- **Limited use of Home Manager.** Home Manager can manage program
  configuration in fine detail. Here it mainly links dotfiles into place from
  the mappings in `dotfiles/dotfiles.json`, similar to GNU Stow. Its options
  step in when a value has to change per host. This means the dotfiles can be
  copied and used outside of nix-darwin.

## Setup

This configuration uses the [Determinate Systems](https://determinate.systems/)
distribution of Nix.

1. **Install Nix:**

    ```bash
    make setup
    ```

2. **Build:**

    ```bash
    make build CONFIG=<CONFIG_NAME>
    ```

3. **Install git hooks** (only needed for development, see [Development](#development)):

    ```bash
    make hooks
    ```

## Adding a New Machine

1. Add a new file `config/<CONFIG_NAME>.nix`. It sets the `host.*` options
    declared in `modules/host.nix`; every option is mandatory, so a machine's
    file describes it completely:

    ```nix
    {
      host = {
        user = "your_username";
        uid = 501; # Replace with your actual UID
        gitUserName = "Your Name";
        gitUserEmail = "your.email@example.com";
        brewUpdates = false; # Set to true to update Homebrew packages on build
        syncDir = "Sync"; # Syncthing folder, relative to home
        vaultDir = "Sync/Cryptomator"; # Encrypted vaults, relative to home
        qgisDir = "Sync/QGIS"; # QGIS user profiles, relative to home
        mountDir = "Vaults"; # Where unlocked vaults are decrypted
        localRoutes = {
          service-name = {
            url = "http://127.0.0.1"; # this machine
            port = 1234;
          };
          device-name = {
            url = "http://x.x.x.x"; # LAN device
            port = 80;
          };
        };
      };
    }
    ```

    Each entry in `localRoutes` is proxied to `url:port`. Both are always
    stated explicitly.

2. Add `<CONFIG_NAME>` to the `machines` list in `flake.nix`.

3. Commit both files.

Options are typed, so a misspelled name or an out-of-range port fails the
build with a message pointing at the mistake, rather than silently producing a
broken configuration.

## Build

Apply the configuration defined in `flake.nix`. The build also writes
`versions.csv`, which lists the installed versions of nixpkgs packages, brews,
casks, and mas apps:

```bash
make build CONFIG=<CONFIG_NAME>
```

## Uninstall

Remove Determinate Nix and related components:

```bash
make uninstall
```

## Development

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

## AI Assistance

Claude Code can be run against this repository inside a Docker Sandboxes
microVM, isolated from the host and with the local network denied. The sandbox
is described in [`.sbx/kit/spec.yaml`](.sbx/kit/spec.yaml) and driven by the
[`Makefile`](Makefile), and Claude Code itself is configured in
[`.sbx/kit/settings.json`](.sbx/kit/settings.json). Running it requires `sbx`,
which must be installed on the host.

| Command | Description |
| --- | --- |
| `make sbx-up` | Build and start the sandbox, replacing any existing one |
| `make sbx-login` | Sign in to Claude Code inside the sandbox |
| `make sbx-agent` | Attach Claude Code to the running sandbox |
| `make sbx-shell` | Open a login shell in the running sandbox |

## Notes

- Some commands may require `sudo` privileges.
- `versions.csv` is not a lockfile — versions may vary machine to machine.
  It provides a rough reference of what versions were present on a working
  system.
