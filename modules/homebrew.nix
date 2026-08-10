# Packages installed via Homebrew. Casks are used for GUI applications because
# nixpkgs symlinks them into /Applications and Spotlight does not index
# symlinks, leaving those applications undiscoverable.
{ config, ... }:

{
  # Install packages via homebrew. Casks are useful for GUI applications
  # that the user wants to access via Spotlight.
  # mas needs to be installed to install packages from App Store.
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
  };
}
