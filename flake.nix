{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
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
      mkSystem =
        hostConfig:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs hostConfig; };
          modules = [
            ./modules/darwin.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users."${hostConfig.user}" = import ./modules/home.nix;
              home-manager.extraSpecialArgs = { inherit hostConfig; };
            }
          ];
        };
    in
    let
      machines = [
        "host00"
        "host01"
      ];
      mkConfig = name: {
        inherit name;
        value = mkSystem (import ./config/${name}.nix);
      };
    in
    {
      darwinConfigurations = builtins.listToAttrs (map mkConfig machines);
    };
}
