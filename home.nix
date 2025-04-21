{
  config,
  pkgs,
  userData,
  ...
}:

{
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.bash.enable = true;

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
      extensions.showRecommendationsOnlyOnDemand = true;
      files.autoSave = "afterDelay";
      workbench.colorTheme = "GitHub Dark";
    };
    extensions = with pkgs.vscode-marketplace; [
      github.github-vscode-theme
      jnoortheen.nix-ide
    ];
  };

  programs.zed-editor = {
    enable = true;
    userSettings = {
      auto_install_extensions = {
        make = true;
        nix = true;
      };
      extensions = [
        "make"
        "nix"
      ];
      vim_mode = true;
    };
  };
}
