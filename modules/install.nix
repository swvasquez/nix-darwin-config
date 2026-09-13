# Everything installed on the machine: command-line tools from nixpkgs,
# formulae, casks, and App Store apps from Homebrew, then the per-app settings
# and shell steps that follow installation on every rebuild.
#
# GUI applications go through Homebrew casks because nixpkgs symlinks them into
# /Applications and Spotlight does not index symlinks, leaving those
# applications undiscoverable. `sbx` (Docker Sandboxes) is a command-line tool
# rather than an application, but Docker publishes it only as a cask, so it is
# listed with them. Using it needs a Docker account: run `sbx login` once after
# installing. `mas` needs to be installed to install packages from App Store.
#
# The Homebrew lists take no trailing comments: scripts/versions.sh scrapes them
# textually, and a comment would be read as part of the package name. Comments
# on their own line are fine.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  user = config.host.user;
  home = config.users.users.${user}.home;

  # Run a shell snippet as the user, inside their launchd session, so it sees
  # their GUI session and creates files they own. `--set-home` matters: sudo
  # otherwise keeps root's HOME, and tools such as the VS Code CLI use it.
  asUser =
    script:
    "launchctl asuser \"$(id -u -- \"${user}\")\" sudo --user=\"${user}\" --set-home -- /bin/sh -c ${lib.escapeShellArg script}";

  cryptomatorDir = "/Library/Application Support/Cryptomator";
  cryptomatorFile = "${cryptomatorDir}/config.properties";

  # `@{userhome}` is substituted by Cryptomator at startup.
  cryptomatorConfig = pkgs.writeText "cryptomator-config.properties" ''
    # Managed by nix-darwin (modules/install.nix). Edits are overwritten.
    cryptomator.mountPointsDir=@{userhome}/${config.host.mountDir}
  '';

  routes = config.host.localRoutes;
in
{
  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow unfree software to be installed via nixpkgs
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.atuin
    pkgs.ansible
    pkgs.bash
    pkgs.bash-preexec # Needed for atuin to work in certain terminals
    pkgs.bat
    pkgs.btop
    pkgs.direnv
    pkgs.elan
    pkgs.eza
    pkgs.ffmpeg_7-full
    pkgs.fzf
    pkgs.gh
    pkgs.git
    pkgs.git-crypt
    pkgs.gitleaks
    pkgs.glow
    pkgs.gnumake # Update MacOS' outdated copy of Make
    pkgs.gnupg
    pkgs.go
    pkgs.helix
    pkgs.hyperfine
    pkgs.jq
    pkgs.just
    pkgs.k9s
    pkgs.kind
    pkgs.kubectl
    pkgs.lazydocker # Needs OrbStack running to provide the Docker socket
    pkgs.lazygit
    pkgs.markdownlint-cli
    pkgs.moreutils
    pkgs.nodejs_22
    pkgs.nixfmt
    pkgs.openbao
    pkgs.pass
    pkgs.poppler-utils
    pkgs.prek
    pkgs.ripgrep
    pkgs.rustup
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.starship
    pkgs.tree
    pkgs.typst
    pkgs.uv
    pkgs.vim
    pkgs.wakeonlan
    pkgs.zellij
    pkgs.zig
    pkgs.zls
    pkgs.zoxide
    pkgs.caddy
  ];

  # Needed to expose bash-preexec.sh at /run/current-system/sw/share/bash/
  environment.pathsToLink = [ "/share/bash" ];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = config.host.brewUpdates;
      cleanup = "uninstall";
      upgrade = config.host.brewUpdates;
    };
    taps = [ ];
    brews = [
      # nixpkgs build fails on darwin
      "bitwarden-cli"
      # nixpkgs helm is not usable on macOS
      "helm"
      "gemini-cli"
      "graphviz"
      # nixpkgs syncthing has no launchd service
      {
        name = "syncthing";
        start_service = true;
        restart_service = "changed";
      }
      # nixpkgs mas could not install Logic Pro
      "mas"
      # nixpkgs yazi on 25.11 (25.5.31) dropped filetype colours under flavors;
      # 26.05 unchecked
      "yazi"
      # nixpkgs yt-dlp lags upstream by months, which breaks YouTube downloads
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
      # nixpkgs Nerd Fonts did not install cleanly; fonts stay on casks
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
      "qgis"
      "raspberry-pi-imager"
      "sbx"
      "spotify"
      # bundles its own tailscale CLI; the nixpkgs one mismatched its version
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

  # QGIS ----------------------------------------------------------------------
  #
  # QGIS's user profile directory, moved into the synced folder so that a second
  # machine opens QGIS with the same settings, plugins, processing models and
  # project templates. QGIS reads the location from QGIS_CUSTOM_CONFIG_PATH and
  # creates a `profiles/` folder beneath it. The variable is set through launchd
  # rather than a shell profile because an app started from Spotlight or the
  # Dock never runs a shell.
  #
  # nix-darwin applies it with `launchctl setenv`, which only reaches processes
  # started afterwards, so QGIS has to be relaunched after a rebuild that
  # changes the path. The profile holds SQLite databases, so close QGIS on one
  # machine before opening it on the other; concurrent writes are a Syncthing
  # conflict, not a merge.
  launchd.user.envVariables.QGIS_CUSTOM_CONFIG_PATH = "${home}/${config.host.qgisDir}";

  # Activation ----------------------------------------------------------------
  #
  # Shell steps that run at the end of every rebuild, after packages are
  # installed. They run as root; `asUser` wraps the ones that must run in the
  # user's session or write to the user's home.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # User directories --------------------------------------------------------
    #
    # Cryptomator's vault and mount directories and QGIS's profile directory,
    # created up front so Syncthing has them to share before the apps first
    # run. Locking a vault only removes the mount; anything an editor or macOS
    # cached from it stays behind, unsynced.
    ${asUser ''
      mkdir -p "${home}/${config.host.vaultDir}"
      mkdir -p "${home}/${config.host.mountDir}"
      mkdir -p "${home}/${config.host.qgisDir}"
    ''}

    # Cryptomator admin config ------------------------------------------------
    #
    # Sets the mount point. Unlike the app's own settings.json, which it
    # rewrites on exit, this file is only read, so the system can own it. Only
    # a fixed allowlist of properties may be set; see AdminPropertiesFactory
    # upstream. A per-vault mount point in Vault Options wins over it, the
    # vault storage location cannot be preset, and macOS prompts once for
    # "network volume" access on first unlock. Copied, not symlinked: the app
    # expects a plain root-owned file.
    /usr/bin/install -d -o root -g wheel -m 755 "${cryptomatorDir}"
    /usr/bin/install -o root -g wheel -m 644 ${cryptomatorConfig} "${cryptomatorFile}"

    # Local proxy hostnames ---------------------------------------------------
    #
    # Point each host.localRoutes name at loopback in /etc/hosts for the Caddy
    # proxy in proxy.nix. Entries carry a marker so stale ones can be removed.
    /usr/bin/sed -i "" '/# nix-local-proxy/d' /etc/hosts
    {
      ${lib.concatMapStrings (name: ''
        echo "127.0.0.1 ${name} # nix-local-proxy"
      '') (lib.attrNames routes)}
    } >> /etc/hosts

    # Apply user defaults now -------------------------------------------------
    #
    # Defaults written earlier in activation (macos.nix) otherwise take effect
    # only after a logout. activateSettings is a private framework binary that
    # must run in the user's GUI session; skipped if missing or headless.
    activateSettings=/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings
    if [ -x "$activateSettings" ]; then
      launchctl asuser "$(id -u -- "${user}")" \
        sudo --user="${user}" -- "$activateSettings" -u || true
    fi

    # Stop macOS from relaunching apps after a restart -----------------------
    #
    # On macOS 26 the "reopen these apps" list is NOT the legacy
    # ByHost/com.apple.loginwindow plist or the TALLogoutSavesState defaults
    # key (both verified ignored via the unified log). loginwindow's
    # PersistentAppsSupport loads the list from a group container instead:
    #   ~/Library/Group Containers/group.com.apple.loginwindow.persistent-apps/persistantApps
    # macOS rewrites that file at every shutdown and reads it at the next boot
    # before activation runs, and there is no supported defaults/MDM key to
    # turn it off. Its only top-level key is PersistentApps, so the fix is to
    # empty that array and mark the file immutable (chflags uchg): the
    # shutdown-time write is then blocked (direct write and atomic rename both
    # verified), so nothing is left to relaunch after any restart, clean
    # shutdown or forced power-off. Runs as the user (the file is in their
    # home); nouchg first keeps rebuilds idempotent. To undo, delete this block
    # and run once:
    #   chflags nouchg ~/Library/Group\ Containers/group.com.apple.loginwindow.persistent-apps/persistantApps
    ${asUser ''
      pa="${home}/Library/Group Containers/group.com.apple.loginwindow.persistent-apps/persistantApps"
      [ -e "$pa" ] || exit 0
      /usr/bin/chflags nouchg "$pa" 2>/dev/null || true
      /usr/libexec/PlistBuddy -c "Delete :PersistentApps" -c "Add :PersistentApps array" "$pa" 2>/dev/null || true
      /usr/bin/chflags uchg "$pa" || true
    ''} || true

    # VS Code extensions ------------------------------------------------------
    #
    # VS Code has no config file that installs extensions, so the ids in
    # dotfiles/vscode/extensions.txt are installed with the app's own CLI.
    # Only missing ones are installed, which keeps a no-change rebuild quiet.
    # Skipped until the cask exists; a failed install warns rather than
    # failing the rebuild.
    ${asUser ''
      code="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
      [ -x "$code" ] || exit 0
      installed=$("$code" --list-extensions)
      grep -v '^#' ${../dotfiles/vscode/extensions.txt} | while read -r id; do
        echo "$installed" | grep -qix "$id" || "$code" --install-extension "$id"
      done
    ''} || echo "warning: some VS Code extensions failed to install" >&2

    # Restart Spotlight -------------------------------------------------------
    #
    # Newly installed apps sometimes stay unfindable in Spotlight even after
    # indexing, and restarting it has cleared that every time. The cause is
    # unknown; this is an empirical fix. launchd relaunches Spotlight
    # immediately; `|| true` covers it not already running.
    ${asUser "killall Spotlight"} || true
  '';
}
