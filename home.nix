{
  config,
  pkgs,
  userData,
  ...
}:

{
  home.stateVersion = "24.11";

  home.file = {
    ".bashrc".source = ./dotfiles/bash/.bashrc;
    ".bash_profile".source = ./dotfiles/bash/.bash_profile;
    ".bash_aliases".source = ./dotfiles/bash/.bash_aliases;
    ".config/starship.toml".source = ./dotfiles/starship/starship.toml;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "${userData.gitUserName}";
    userEmail = "${userData.gitUserEmail}";
    extraConfig.core.editor = "vim";
  };

  programs.helix.enable = true;
  programs.lazygit.enable = true;

  programs.vscode = {
    enable = true;
    userSettings = {
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
      timonwong.shellcheck
    ];
  };

  programs.zed-editor = {
    enable = true;
    extensions = [
      "basher"
      "make"
      "nix"
    ];
    userSettings = {
      auto_install_extensions = {
        basher = true;
        make = true;
        nix = true;
      };
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      autosave.after_delay.milliseconds = 1000;
      helix_mode = true;
    };
  };

  programs.zellij = {
    enable = true;
    settings = {
      simplified_ui = true;
    };
  };
}
