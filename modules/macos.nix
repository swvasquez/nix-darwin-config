# macOS user-interface and input settings. The activation steps that make some
# of them take effect in the running session are in install.nix.
{ ... }:

{
  # Show hidden files in Finder
  system.defaults.finder.AppleShowAllFiles = true;
  system.defaults.finder._FXSortFoldersFirst = true;

  # Enable tap-to-click. Takes effect, but the System Settings toggle does not
  # reflect it.
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

  # Delay before Dock appears on hover; a large value (e.g. 1000) effectively hides it always
  system.defaults.dock.autohide-delay = 0.0;

  # Time it takes for the to Dock appear/hide
  system.defaults.dock.autohide-time-modifier = 0.15;

  # Disable bouncing application animation
  system.defaults.dock.launchanim = false;

  # Keep Spaces in a fixed order instead of rearranging them by most recent
  # use, so the ⌃1-⌃9 desktop shortcuts always target the same desktop
  system.defaults.dock.mru-spaces = false;

  # Disable desktop from showing when wallpaper is clicked
  system.defaults.WindowManager.EnableStandardClickToShowDesktop = false;

  # Hide desktop items
  system.defaults.WindowManager.StandardHideDesktopIcons = true;

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
    "/Applications/Claude.app"
    "/Applications/Zotero.app"
    "/System/Applications/System Settings.app"
  ];

}
