# macOS user-interface and input settings, plus the activation workarounds
# needed to make some of them take effect.
{ config, lib, ... }:

{
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

  # Enable Touch ID for Sudo
  security.pam.services.sudo_local.touchIdAuth = true;

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

  system.activationScripts.postActivation.text = lib.mkAfter ''
    # Without this, user defaults written earlier in activation (e.g. the
    # symbolic hotkeys) only take effect after a logout/login; activateSettings
    # makes the running session re-read them immediately. It is a private
    # framework binary that must run inside the user's GUI session; activation
    # runs under `set -e`, so skip it quietly if macOS ever removes it or there
    # is no session (headless rebuilds).
    activateSettings=/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings
    if [ -x "$activateSettings" ]; then
      launchctl asuser "$(id -u -- "${config.host.user}")" \
        sudo --user="${config.host.user}" -- "$activateSettings" -u || true
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
    launchctl asuser "$(id -u -- "${config.host.user}")" \
      sudo --user="${config.host.user}" -- /bin/sh -c '
        pa="/Users/${config.host.user}/Library/Group Containers/group.com.apple.loginwindow.persistent-apps/persistantApps"
        [ -e "$pa" ] || exit 0
        /usr/bin/chflags nouchg "$pa" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Delete :PersistentApps" -c "Add :PersistentApps array" "$pa" 2>/dev/null || true
        /usr/bin/chflags uchg "$pa" || true
      ' || true
  '';
}
