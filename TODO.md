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

## Resolved

## Closed
