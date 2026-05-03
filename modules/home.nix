{
  config,
  pkgs,
  hostConfig,
  ...
}:

{
  home.stateVersion = "25.11";

  # Dotfile mappings are defined in dotfiles/dotfiles.json.
  # Add entries there to symlink additional files without modifying this file.
  home.file =
    let
      mappings = builtins.fromJSON (builtins.readFile ../dotfiles/dotfiles.json);
    in
    builtins.listToAttrs (
      map (m: {
        name = m.dest;
        value = {
          source = ../dotfiles + "/${m.src}";
        };
      }) mappings
    );

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "${hostConfig.gitUserName}";
        email = "${hostConfig.gitUserEmail}";
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
