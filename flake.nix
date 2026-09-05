{
  description = "nix-darwin system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
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
      # Each machine is described by config/<name>.nix, which sets the `host.*`
      # options declared in modules/options.nix. Those options are read via
      # `config.host` by the modules below, so nothing is threaded through
      # specialArgs except the flake inputs themselves.
      mkSystem =
        hostModule:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./modules/options.nix
            hostModule
            ./modules/core.nix
            ./modules/install.nix
            ./modules/macos.nix
            ./modules/proxy.nix
            home-manager.darwinModules.home-manager
            ./modules/home-manager.nix
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
        value = mkSystem ./config/${name}.nix;
      };
    in
    {
      darwinConfigurations = builtins.listToAttrs (map mkConfig machines);
    };
}
