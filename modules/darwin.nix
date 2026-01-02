{
  pkgs,
  inputs,
  userData,
  ...
}:

{
  # Turn off nix-darwin’s management of the Nix installation
  nix.enable = false;

  # Allow nix-darwin to configure Zsh
  programs.zsh.enable = false;

  # Specify user using data from user-data.nix
  users.users."${userData.user}" = {
    name = "${userData.user}";
    home = "/Users/${userData.user}";
    uid = userData.uid;
    shell = pkgs.bashInteractive; # Updates MacOS' outdated copy of bash
  };
  users.knownUsers = [ "${userData.user}" ];
  system.primaryUser = "${userData.user}";

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # Show hidden files in Finder
  system.defaults.finder.AppleShowAllFiles = true;
  system.defaults.finder._FXSortFoldersFirst = true;

  # Enable tap-to-click
  system.defaults.trackpad.Clicking = true;

  # Remap caps lock key to escape
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow unfree software to be installed via nixpkgs
  nixpkgs.config.allowUnfree = true;

  # Enable Touch ID for Sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.ansible
    pkgs.bash
    pkgs.fzf
    pkgs.gnumake # Update MacOS' outdated copy of Make
    pkgs.gnupg
    pkgs.go
    pkgs.helix
    pkgs.jq
    pkgs.just
    pkgs.kind
    pkgs.markdownlint-cli
    pkgs.moreutils
    pkgs.nodejs_22
    pkgs.nixfmt-rfc-style
    pkgs.pass
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.starship
    pkgs.uv
    pkgs.vim
    pkgs.wakeonlan
  ];

  # Install packages via homebrew. Casks are useful for GUI applications
  # that the user wants to access via Spotlight.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
    taps = [ ];
    brews = [
      "bitwarden-cli"
      "gemini-cli"
    ];
    casks = [
      "bitwarden"
      "claude-code"
      "discord"
      "firefox"
      "ghostty"
      "google-chrome"
      "iina"
      "iterm2"
      "keepassxc"
      "libreoffice"
      "logseq"
      "mullvad-browser"
      "mullvad-vpn"
      "obsidian"
      "ollama-app"
      "orbstack"
      "raspberry-pi-imager"
      "spotify"
      "tailscale-app"
      "visual-studio-code"
      "winbox"
      "zed"
      "zotero"
    ];
    "masApps" = {
      "Logic Pro" = 634148309;
    };
  };

  # Prevent Dock from showing recently used applications
  system.defaults.dock.show-recents = false;

  # Hide Dock when cursor is hovering elsewhere
  system.defaults.dock.autohide = true;

  # Delay between displaying Dock and activation
  system.defaults.dock.autohide-delay = 0.0;

  # Time it takes for the to Dock appear/hide
  system.defaults.dock.autohide-time-modifier = 0.15;

  # Disable bouncing application animation
  system.defaults.dock.launchanim = false;

  # Disable desktop from showing when wallpaper is clicked
  system.defaults.WindowManager.EnableStandardClickToShowDesktop = false;

  # Specify applications to be displayed in Dock
  system.defaults.dock.persistent-apps = [
    "/Applications/Logseq.app"
    "/Applications/Firefox.app"
    "/Applications/Spotify.app"
    "/Applications/iTerm.app"
    "/Applications/Visual Studio Code.app"
    "/Applications/Zed.app"
    "/Applications/Zotero.app"
    "/System/Applications/Shortcuts.app"
    "/System/Applications/System Settings.app"
  ];

  # Use overlays to customize nixpkgs
  nixpkgs.overlays = [
    inputs.nix-vscode-extensions.overlays.default
  ];
}
