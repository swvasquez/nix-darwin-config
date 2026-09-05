# Home Manager, enabled for the primary user with that user's configuration
# inline. It only links dotfiles into place, Stow-style; packages belong in
# install.nix.
{ config, ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # A Home Manager module, not a nix-darwin one: it sees Home Manager's options,
  # and the system configuration is reachable through `osConfig`.
  home-manager.users.${config.host.user} =
    { osConfig, ... }:
    {
      home.stateVersion = "26.05";

      # Dotfiles are mapped in dotfiles/dotfiles.json. A destination or file
      # contents may contain @syncDir@, @gitUserName@ or @gitUserEmail@, which
      # are replaced with the matching host.* value. Starship's bash init lives
      # in dotfiles/bash/.bashrc because
      # programs.starship.enableBashIntegration never took effect.
      home.file =
        let
          mappings = builtins.fromJSON (builtins.readFile ../dotfiles/dotfiles.json);
          substitute =
            builtins.replaceStrings
              [ "@syncDir@" "@gitUserName@" "@gitUserEmail@" ]
              [
                osConfig.host.syncDir
                osConfig.host.gitUserName
                osConfig.host.gitUserEmail
              ];
        in
        builtins.listToAttrs (
          map (m: {
            name = substitute m.dest;
            value = {
              text = substitute (builtins.readFile (../dotfiles + "/${m.src}"));
            };
          }) mappings
        );

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;
    };
}
