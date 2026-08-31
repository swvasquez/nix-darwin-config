{
  lib,
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

  # Create both Cryptomator directories up front: host.vaultDir for the
  # encrypted vaults, host.mountDir for where an unlocked one is decrypted.
  # cryptomator.nix points the app at mountDir; host.nix asserts they cannot
  # overlap syncDir. Note that locking only removes the mount — plaintext an
  # editor or macOS cached meanwhile outlives it, unsynced but uncleaned.
  home.activation.cryptomatorDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/${osConfig.host.vaultDir}"
    run mkdir -p "$HOME/${osConfig.host.mountDir}"
  '';

  # QGIS creates its `profiles/` folder beneath this directory on first run;
  # qgis.nix points the app at it through QGIS_CUSTOM_CONFIG_PATH. Created here
  # so Syncthing has the folder to share before QGIS is ever opened.
  home.activation.qgisDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/${osConfig.host.qgisDir}"
  '';

  # Newly installed applications sometimes stay unfindable in Spotlight even
  # once the metadata index has caught up, and restarting Spotlight has cleared
  # it every time. That is the extent of what is established: the fix is
  # empirical, not a diagnosis. Whether the install method matters is unknown,
  # as is the cause — a stale app list cached by the search UI process is only a
  # guess, and killing the process is blunt enough to mask several other
  # candidates. launchd relaunches it immediately; `|| true` covers it not
  # already running.
  home.activation.restartSpotlight = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run killall Spotlight || true
  '';

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
