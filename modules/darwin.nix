{
  pkgs,
  lib,
  inputs,
  hostConfig,
  ...
}:
let
  routes = hostConfig.localRoutes;
  caddyfile = pkgs.writeText "Caddyfile" (
    ''
      {
        auto_https off
      }

    ''
    + lib.concatMapStrings (
      route:
      if route ? port then
        ''
          http://${route.name} {
            reverse_proxy 127.0.0.1:${toString route.port} {
              header_up Host localhost
            }
          }

        ''
      else if lib.hasPrefix "https://" route.url then
        ''
          http://${route.name} {
            reverse_proxy ${route.url} {
              transport http {
                tls_insecure_skip_verify
              }
            }
          }

        ''
      else
        ''
          http://${route.name} {
            reverse_proxy ${route.url}
          }

        ''
    ) routes
  );
in
{
  # Turn off nix-darwin’s management of the Nix installation
  nix.enable = false;

  # Allow nix-darwin to configure Zsh
  programs.zsh.enable = false;

  # Specify user using data from config/
  users.users."${hostConfig.user}" = {
    name = "${hostConfig.user}";
    home = "/Users/${hostConfig.user}";
    uid = hostConfig.uid;
    shell = pkgs.bashInteractive; # Updates MacOS' outdated copy of bash
  };
  users.knownUsers = [ "${hostConfig.user}" ];
  system.primaryUser = "${hostConfig.user}";

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # Show hidden files in Finder
  system.defaults.finder.AppleShowAllFiles = true;
  system.defaults.finder._FXSortFoldersFirst = true;

  # Enable tap-to-click
  system.defaults.trackpad.Clicking = true;

  # Remap caps lock key to escape
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;

  # Remap right option to right control
  # Verify with: hidutil property --get UserKeyMapping
  system.keyboard.userKeyMapping = [
    {
      HIDKeyboardModifierMappingSrc = 30064771302;
      HIDKeyboardModifierMappingDst = 30064771300;
    }
  ];

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow unfree software to be installed via nixpkgs
  nixpkgs.config.allowUnfree = true;

  # Enable Touch ID for Sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.atuin
    pkgs.ansible
    pkgs.bash
    pkgs.bash-preexec # Needed for atuin to work in certain terminals
    pkgs.btop
    pkgs.direnv
    pkgs.elan
    pkgs.ffmpeg_7-full
    pkgs.fzf
    pkgs.gh
    pkgs.git-crypt
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
    pkgs.markdownlint-cli
    pkgs.moreutils
    pkgs.nodejs_22
    pkgs.nixfmt-rfc-style
    pkgs.openbao
    pkgs.pass
    pkgs.poppler-utils
    pkgs.ripgrep
    pkgs.rustup
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.starship
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

  # Local reverse proxy: maps friendly hostnames to localhost ports.
  # Routes are defined in config/<host>.nix as localRoutes = [{ name = "...", port = ...; }].
  system.activationScripts.postActivation.text = lib.mkAfter ''
    /usr/bin/sed -i "" '/# nix-local-proxy/d' /etc/hosts
    {
      ${lib.concatMapStrings (route: ''
        echo "127.0.0.1 ${route.name} # nix-local-proxy"
      '') routes}
    } >> /etc/hosts

    # Without this, user defaults written earlier in activation (e.g. the
    # symbolic hotkeys) only take effect after a logout/login; activateSettings
    # makes the running session re-read them immediately. It is a private
    # framework binary that must run inside the user's GUI session; activation
    # runs under `set -e`, so skip it quietly if macOS ever removes it or there
    # is no session (headless rebuilds).
    activateSettings=/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings
    if [ -x "$activateSettings" ]; then
      launchctl asuser "$(id -u -- "${hostConfig.user}")" \
        sudo --user="${hostConfig.user}" -- "$activateSettings" -u || true
    fi

    # Stop macOS from relaunching apps after a restart/shutdown. On macOS 26 the
    # "reopen these apps" list is NOT the legacy ByHost/com.apple.loginwindow
    # plist or the TALLogoutSavesState defaults key (both verified ignored via
    # the unified log). loginwindow's PersistentAppsSupport loads the list from a
    # group container instead:
    #   ~/Library/Group Containers/group.com.apple.loginwindow.persistent-apps/persistantApps
    # macOS rewrites that file at every shutdown and reads it at the next boot
    # before activation runs, and there is no supported defaults/MDM key to turn
    # it off. Its only top-level key is PersistentApps, so the fix is to empty
    # that array and mark the file immutable (chflags uchg): the shutdown-time
    # write is then blocked (direct write and atomic rename both verified), so
    # nothing is left to relaunch after any restart — clean shutdown or forced
    # power-off. Runs as the user (the file is in their home); nouchg first keeps
    # rebuilds idempotent. To undo, delete this block and run once:
    #   chflags nouchg ~/Library/Group\ Containers/group.com.apple.loginwindow.persistent-apps/persistantApps
    launchctl asuser "$(id -u -- "${hostConfig.user}")" \
      sudo --user="${hostConfig.user}" -- /bin/sh -c '
        pa="/Users/${hostConfig.user}/Library/Group Containers/group.com.apple.loginwindow.persistent-apps/persistantApps"
        [ -e "$pa" ] || exit 0
        /usr/bin/chflags nouchg "$pa" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Delete :PersistentApps" -c "Add :PersistentApps array" "$pa" 2>/dev/null || true
        /usr/bin/chflags uchg "$pa" || true
      ' || true
  '';

  launchd.daemons.caddy = {
    # Use `command` rather than serviceConfig.ProgramArguments: nix-darwin only
    # wraps the former in `/bin/wait4path /nix/store && exec ...`. Without that
    # guard a boot can beat the /nix volume mount, launchd finds no executable,
    # and parks the job permanently (KeepAlive only revives jobs that actually
    # ran, not ones that failed to launch). See nix-darwin issue #1043.
    command = "${pkgs.caddy}/bin/caddy run --config ${caddyfile} --adapter caddyfile";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/caddy.log";
      StandardErrorPath = "/var/log/caddy.err.log";
      # launchd starts daemons with no $HOME, so Caddy falls back to a relative
      # ./caddy data dir and fails to create its storage (read-only cwd), exiting
      # 78/EX_CONFIG. Point HOME at root's home (the passwd default) so Caddy uses
      # /var/root/Library/Application Support/Caddy.
      EnvironmentVariables = {
        HOME = "/var/root";
      };
    };
  };

  # Rotate Caddy's launchd logs via macOS's built-in newsyslog job.
  # Rotate at 5 MB, keep 5 bzip2-compressed copies (size-triggered only).
  environment.etc."newsyslog.d/caddy.conf".text = ''
    # logfilename          [owner:group]  mode count size(KB) when  flags
    /var/log/caddy.log      root:wheel     644  5     5120     *     J
    /var/log/caddy.err.log  root:wheel     644  5     5120     *     J
  '';

  # Install packages via homebrew. Casks are useful for GUI applications
  # that the user wants to access via Spotlight.
  # mas needs to be installed to install packages from App Store.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = hostConfig.brewUpdates;
      cleanup = "uninstall";
      upgrade = hostConfig.brewUpdates;
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

  # Move Dock to the right side of the screen
  system.defaults.dock.orientation = "right";

  # Prevent Dock from showing recently used applications
  system.defaults.dock.show-recents = false;

  # Hide Dock when cursor is hovering elsewhere
  system.defaults.dock.autohide = true;

  # Effectively disable Dock (never shows on hover; toggle with ⌥⌘D)
  system.defaults.dock.autohide-delay = 1000.0;

  # Time it takes for the to Dock appear/hide
  system.defaults.dock.autohide-time-modifier = 0.15;

  # Disable bouncing application animation
  system.defaults.dock.launchanim = false;

  # Keep Spaces in a fixed order instead of rearranging them by most recent
  # use, so the ⌃1-⌃9 desktop shortcuts always target the same desktop
  system.defaults.dock.mru-spaces = false;

  # Disable desktop from showing when wallpaper is clicked
  system.defaults.WindowManager.EnableStandardClickToShowDesktop = false;

  # Reduce motion (Accessibility): swap the space-switching/app-opening
  # animations for quick fades.
  # NOTE: com.apple.universalaccess is TCC-protected — the terminal running
  # darwin-rebuild needs Full Disk Access, or this write fails activation.
  system.defaults.universalaccess.reduceMotion = true;

  # Prevent pinentry-mac from saving the GPG passphrase to the login keychain
  system.defaults.CustomUserPreferences = {
    "org.gpgtools.pinentry-mac" = {
      UseKeychain = false;
    };
  };

  # Enable the Mission Control "Switch to Desktop 1-9" shortcuts (⌃1-⌃9).
  # There is no single option that enables these as a group: macOS stores one
  # symbolic hotkey entry per desktop (IDs 118-126 for Desktops 1-9), so each
  # desktop's shortcut has to be set individually — hence the nine entries
  # generated below. Each entry's parameter list is
  # [ asciiCode virtualKeycode modifierMask ], with 262144 being the Ctrl mask.
  # NOTE: activation replaces the whole AppleSymbolicHotKeys dict. That is
  # intentional — keyboard shortcuts are managed declaratively here, so any
  # customization made by hand in System Settings (same dict) resets to macOS
  # defaults on the next rebuild; declare shortcut changes here instead.
  system.defaults.CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys =
    let
      # ANSI virtual keycodes for the digit keys 1-9
      digitKeycodes = [
        18
        19
        20
        21
        23
        22
        26
        28
        25
      ];
    in
    builtins.listToAttrs (
      builtins.genList (i: {
        name = toString (118 + i);
        value = {
          enabled = 1;
          value = {
            parameters = [
              (49 + i) # ASCII code of the digit (i + 1)
              (builtins.elemAt digitKeycodes i)
              262144
            ];
            type = "standard";
          };
        };
      }) 9
    );

  # Specify applications to be displayed in Dock
  system.defaults.dock.persistent-apps = [
    "/Applications/Logseq-OG.app"
    "/Applications/Firefox.app"
    "/Applications/Spotify.app"
    "/Applications/Ghostty.app"
    "/Applications/Zed.app"
    "/Applications/Zotero.app"
    "/System/Applications/System Settings.app"
  ];

  # Use overlays to customize nixpkgs
  nixpkgs.overlays = [
    inputs.nix-vscode-extensions.overlays.default
  ];
}
