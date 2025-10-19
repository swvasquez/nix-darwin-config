# TODO

This document tracks undesirable behaviors and bugs that may be encountered when
using this repository.  

## To-do

- In order for `nix-darwin` to update the user's shell, the user must be added to
`knownHosts`. An error arises when adding a user to `knownHosts` if the user's ID
is not provided.
- GUI applications installed by nixpkgs are symlinked into the Applications
folder. Because Spotlight doesn't index symlinks, nixpkgs GUI applications are
not discoverable. As a workaround, GUI applications can be enabled via Homebrew
and configured via Home Manager.
- The `$PATH` environment variable accessed through the VS Code integrated terminal
differs from that accessed through a dedicated terminal. This difference causes
`bash` to point to the original (outdated) version instead of the one installed via
`nix-darwin`.
- Setting `system.defaults.trackpad.Clicking = true` alters the trackpad
behavior as expected, but the associated indicator in System Settings remains
unchanged.
- `bitwarden-cli` fails to build when installed by `nixpkgs`.
- Soon after updating MacOS to 26.0, rebuilding would raise an error regarding
unexpected files `/etc/{zshrc,zprofile}`. Setting `programs.zsh.enable = false;`
resolved the issue. If this issue was in fact related to the OS update, it may
be addressed by future versions of `nix-darwin`.
- Trouble installing Nerd Fonts via `nixpkgs`.
- The Home Manager option to enable Bash integration with Starship doesn't seem
to work. Manually managing associated dotfile instead.
- Noticed that running either `bash -l` or `exec bash -l` loads the initially
installed, older version of Bash.

## Resolved

## Closed
