# Baseline system settings: the Nix installation itself, the primary user, and
# the versioning fields nix-darwin uses to track this configuration.
{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # Turn off nix-darwin’s management of the Nix installation
  nix.enable = false;

  # Enabling this after the macOS 26.0 update made rebuilds fail on unexpected
  # /etc/{zshrc,zprofile}; possibly fixed in a later nix-darwin.
  programs.zsh.enable = false;

  # Specify user using data from config/
  users.users."${config.host.user}" = {
    name = "${config.host.user}";
    home = "/Users/${config.host.user}";
    uid = config.host.uid;
    # Updates MacOS' outdated copy of bash. `bash -l` still lands in the old
    # /bin/bash, as does the VS Code integrated terminal.
    shell = pkgs.bashInteractive;
  };
  users.knownUsers = [ "${config.host.user}" ];
  system.primaryUser = "${config.host.user}";

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
