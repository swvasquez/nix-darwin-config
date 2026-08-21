# Cryptomator's mount point, set through its admin configuration.
#
# Unlike the app's own settings.json, which it rewrites on exit, this file is
# only ever read, so the system can own it. Only a fixed allowlist of properties
# may be overridden; see AdminPropertiesFactory upstream.
#
# Worth knowing before relying on this: a mount point set per vault in Vault
# Options wins over it, the vault storage location cannot be preset at all, and
# macOS prompts once for "network volume" access when a vault is first unlocked.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  configDir = "/Library/Application Support/Cryptomator";
  configFile = "${configDir}/config.properties";

  # `@{userhome}` is substituted by Cryptomator at startup.
  adminConfig = pkgs.writeText "cryptomator-config.properties" ''
    # Managed by nix-darwin (modules/cryptomator.nix). Edits are overwritten.
    cryptomator.mountPointsDir=@{userhome}/${config.host.mountDir}
  '';
in
{
  # Copied, not symlinked: the app expects a plain root-owned file. A missing or
  # malformed one is logged and ignored rather than fatal.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    /usr/bin/install -d -o root -g wheel -m 755 "${configDir}"
    /usr/bin/install -o root -g wheel -m 644 ${adminConfig} "${configFile}"
  '';
}
