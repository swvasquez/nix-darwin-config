# QGIS's user profile directory, moved into the synced folder so that a second
# machine opens QGIS with the same settings, plugins, processing models and
# project templates rather than a fresh configuration.
#
# QGIS takes the location from QGIS_CUSTOM_CONFIG_PATH — the environment
# equivalent of its --profiles-path flag — and creates a `profiles/` folder
# beneath it, one subfolder per profile. The path is exported through launchd
# rather than a shell profile because an application started from Spotlight or
# the Dock inherits its environment from the user's launchd session and never
# runs a shell.
#
# Worth knowing before relying on this: nix-darwin applies the variable with
# `launchctl setenv`, which only reaches processes started afterwards, so QGIS
# has to be relaunched after a rebuild that changes the path. The profile holds
# SQLite databases, so QGIS should be closed on one machine before it is opened
# on the other; two sessions writing at once is a Syncthing conflict, not a
# merge.
{ config, ... }:

let
  home = config.users.users.${config.host.user}.home;
in
{
  launchd.user.envVariables.QGIS_CUSTOM_CONFIG_PATH = "${home}/${config.host.qgisDir}";
}
