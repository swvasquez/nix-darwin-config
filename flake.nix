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
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#default
      darwinConfigurations."default" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs userData; };
        modules = [
          ./modules/darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users."${userData.user}" = import ./modules/home.nix;
            home-manager.extraSpecialArgs = { inherit userData; };
          }
        ];
      };
    };
}
