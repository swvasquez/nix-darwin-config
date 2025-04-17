{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
    }:
    let
      # Load user-specific data from user-data.nix
      userData = import ./user-data.nix;
      configuration =
        { pkgs, ... }:
        {
          # Turn off nix-darwin’s management of the Nix installation
          nix.enable = false;

          # Specify user using data from user-data.nix
          users.users."${userData.user}" = {
            name = "${userData.user}";
            home = "/Users/${userData.user}";
            uid = userData.uid;
            shell = pkgs.bashInteractive; # Updates MacOS' outdated copy of bash
          };
          users.knownUsers = [ "${userData.user}" ];

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.nixfmt-rfc-style
            pkgs.markdownlint-cli
            pkgs.vim
          ];

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#default
      darwinConfigurations."default" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          {
            users.users."${userData.user}" = {
              name = "${userData.user}";
              home = "/Users/${userData.user}";
            };
          }
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
