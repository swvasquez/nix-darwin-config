# System configuration, split by concern. Per-machine values come from
# config/<name>.nix via the host.* options declared in host.nix.
{
  imports = [
    ./core.nix
    ./cryptomator.nix
    ./homebrew.nix
    ./macos.nix
    ./packages.nix
    ./proxy.nix
    ./qgis.nix
  ];
}
