{
  pkgs,
  osConfig,
  ...
}:

{
  home.stateVersion = "25.11";

  # Dotfile mappings are defined in dotfiles/dotfiles.json.
  # Add entries there to symlink additional files without modifying this file.
  #
  # A destination may contain @syncDir@, which is replaced with host.syncDir so
  # the mapping follows that option instead of hardcoding the directory name.
  home.file =
    let
      mappings = builtins.fromJSON (builtins.readFile ../dotfiles/dotfiles.json);
    in
    builtins.listToAttrs (
      map (m: {
        name = builtins.replaceStrings [ "@syncDir@" ] [ osConfig.host.syncDir ] m.dest;
        value = {
          source = ../dotfiles + "/${m.src}";
        };
      }) mappings
    );

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    ignores = [ ".DS_Store" ];
    settings = {
      user = {
        name = osConfig.host.gitUserName;
        email = osConfig.host.gitUserEmail;
      };
      core.editor = "hx";
    };
  };

  programs.lazygit.enable = true;

  programs.vscode = {
    enable = true;
    profiles.default = {
      userSettings = {
        chat.disableAIFeatures = true;
        editor.minimap.enabled = false;
        extensions.showRecommendationsOnlyOnDemand = true;
        files.autoSave = "afterDelay";
        telemetry.telemetryLevel = "off";
        workbench.colorTheme = "GitHub Dark";

      };
      extensions = with pkgs.vscode-marketplace; [
        github.github-vscode-theme
        jnoortheen.nix-ide
        leanprover.lean4
        nefrob.vscode-just-syntax
        redhat.ansible
        tailscale.vscode-tailscale
        timonwong.shellcheck
      ];
    };
  };
}
