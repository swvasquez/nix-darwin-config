{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      nix-vscode-extensions,
    }:
    let
      # Load user-specific data from user-data.nix
      userData = import ./user-data.nix;
      configuration =
        { pkgs, ... }:
        {
          # Turn off nix-darwin’s management of the Nix installation
          nix.enable = false;

          # Allow nix-darwin to configure zsh
          programs.zsh.enable = false;

          # Specify user using data from user-data.nix
          users.users."${userData.user}" = {
            name = "${userData.user}";
            home = "/Users/${userData.user}";
            uid = userData.uid;
            shell = pkgs.bashInteractive; # Updates MacOS' outdated copy of bash
          };
          users.knownUsers = [ "${userData.user}" ];

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # Show hidden files in Finder
          system.defaults.finder.AppleShowAllFiles = true;
          system.defaults.finder._FXSortFoldersFirst = true;

          # Enable tap-to-click
          system.defaults.trackpad.Clicking = true;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          # Allow unfree software to be installed via nixpkgs
          nixpkgs.config.allowUnfree = true;

          # Enable Touch ID for Sudo
          security.pam.enableSudoTouchIdAuth = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.bash
            pkgs.fzf
            pkgs.gnumake # Update MacOS' outdated copy of Make
            pkgs.gnupg
            pkgs.jq
            pkgs.just
            pkgs.markdownlint-cli
            pkgs.moreutils
            pkgs.nodejs_22
            pkgs.nixfmt-rfc-style
            pkgs.pass
            pkgs.shellcheck
            pkgs.shfmt
            pkgs.uv
            pkgs.vim
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
            brews = [ "bitwarden-cli" ];
            casks = [
              "bitwarden"
              "firefox"
              "google-chrome"
              "iina"
              "iterm2"
              "keepassxc"
              "logseq"
              "obsidian"
              "ollama-app"
              "orbstack"
              "spotify"
              "visual-studio-code"
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
            nix-vscode-extensions.overlays.default
          ];
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#default
      darwinConfigurations."default" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users."${userData.user}" = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit userData; };
          }
        ];
      };
    };
}
