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

  programs.git = {
    enable = true;
    userName = "${userData.gitUserName}";
    userEmail = "${userData.gitUserEmail}";
  };
}
