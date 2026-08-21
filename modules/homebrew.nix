# Packages installed via Homebrew. Casks are used for GUI applications because
# nixpkgs symlinks them into /Applications and Spotlight does not index
# symlinks, leaving those applications undiscoverable.
{ config, ... }:

{
  # Install packages via homebrew. Casks are useful for GUI applications
  # that the user wants to access via Spotlight. `sbx` (Docker Sandboxes) is a
  # command-line tool rather than an application, but Docker publishes it only
  # as a cask, so it is listed with them. Using it needs a Docker account: run
  # `sbx login` once after installing.
  # mas needs to be installed to install packages from App Store.
  # The lists below take no trailing comments: scripts/versions.sh scrapes them
  # textually, and a comment would be read as part of the package name.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = config.host.brewUpdates;
      cleanup = "uninstall";
      upgrade = config.host.brewUpdates;
    };
    taps = [ ];
    brews = [
      "bitwarden-cli"
      "helm"
      "gemini-cli"
      "graphviz"
      {
        name = "syncthing";
        start_service = true;
        restart_service = "changed";
      }
      "mas"
      "yazi"
      "yt-dlp"
    ];
    casks = [
      "bitwarden"
      "blackhole-16ch"
      "claude"
      "claude-code"
      "cryptomator"
      "discord"
      "firefox"
      "font-linux-libertine"
      "ghostty"
      "github"
      "google-chrome"
      "iina"
      "iterm2"
      "keepassxc"
      "libreoffice"
      "logseq"
      "logseq-og"
      "mullvad-browser"
      "mullvad-vpn"
      "obsidian"
      "orbstack"
      "raspberry-pi-imager"
      "sbx"
      "spotify"
      "tailscale-app"
      "visual-studio-code"
      "winbox"
      "zed"
      "zotero"
    ];
    "masApps" = {
      "Logic Pro" = 634148309;
    };

    # Third-party taps. Homebrew refuses to load a formula or cask from an
    # unofficial tap until that tap is trusted, and trust is recorded in
    # ~/.homebrew/trust.json rather than the Brewfile. `brew bundle` grants it
    # for entries marked `trusted:`, before it loads anything, so declaring the
    # tap here is enough. It goes in extraConfig rather than `taps` above
    # because nix-darwin's tap options predate this Homebrew feature and cannot
    # express `trusted`. Keeping trust in the Brewfile also means a
    # `brew bundle cleanup --force`, which rewrites the trust store from the
    # Brewfile, preserves it instead of discarding it.
    extraConfig = ''
      tap "docker/tap", trusted: true
    '';
  };
}
