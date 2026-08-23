{ config, lib, ... }:

let
  routeType = lib.types.submodule {
    options = {
      url = lib.mkOption {
        type = lib.types.str;
        description = ''
          Scheme and host of the upstream this route proxies to. Use
          `http://127.0.0.1` for a service running on this machine. An
          `https://` upstream is dialed without certificate verification, since
          LAN devices generally present self-signed certificates.
        '';
        example = "http://192.168.0.2";
      };

      port = lib.mkOption {
        type = lib.types.port;
        description = "Port on the upstream host.";
        example = 8384;
      };
    };
  };

  cfg = config.host;

  # The comparison below is textual, so "Sync", "Sync/" and "./Sync" must reduce
  # to one form first.
  normalise =
    dir: lib.concatStringsSep "/" (lib.filter (p: p != "" && p != ".") (lib.splitString "/" dir));

  # Whether two directories are the same or one contains the other. `..` is not
  # resolved (impossible without the real filesystem), so a path using one is
  # the caller's to check.
  overlaps =
    a: b:
    let
      a' = normalise a;
      b' = normalise b;
    in
    a' == b' || lib.hasPrefix "${a'}/" b' || lib.hasPrefix "${b'}/" a';
in
{
  # Per-machine settings. Every option is mandatory: a machine's config in
  # config/<name>.nix states each value explicitly rather than inheriting a
  # default from here, so that file is a complete description of the machine.
  options.host = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "Username of the machine's primary (and only) user.";
      example = "ada";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      description = ''
        Numeric user ID. nix-darwin will not manage a user's shell unless that
        user appears in `users.knownUsers`, which in turn requires a uid. 501 is
        the first user account macOS creates.
      '';
      example = 501;
    };

    gitUserName = lib.mkOption {
      type = lib.types.str;
      description = "Value of git's `user.name`.";
      example = "Ada Lovelace";
    };

    gitUserEmail = lib.mkOption {
      type = lib.types.str;
      description = "Value of git's `user.email`.";
      example = "ada@example.com";
    };

    brewUpdates = lib.mkOption {
      type = lib.types.bool;
      description = ''
        Whether a rebuild updates Homebrew itself and upgrades the installed
        formulae and casks. Homebrew is not pinned the way nixpkgs is, so
        enabling this trades reproducibility for recency.
      '';
      example = false;
    };

    syncDir = lib.mkOption {
      type = lib.types.str;
      description = ''
        Directory, relative to the home directory, that Syncthing shares between
        machines.
      '';
      example = "Sync";
    };

    vaultDir = lib.mkOption {
      type = lib.types.str;
      description = ''
        Directory, relative to the home directory, holding Cryptomator's
        encrypted vaults. Only ciphertext is written here, so it belongs inside
        `syncDir`. Stated in full, not relative to it.
      '';
      example = "Sync/Cryptomator";
    };

    qgisDir = lib.mkOption {
      type = lib.types.str;
      description = ''
        Directory, relative to the home directory, holding QGIS's user profiles:
        its settings, installed plugins, processing models and scripts, and
        project templates. It belongs inside `syncDir`, so that a second machine
        starts QGIS with the same configuration. Stated in full, not relative to
        it. Applied by qgis.nix as `QGIS_CUSTOM_CONFIG_PATH`.
      '';
      example = "Sync/QGIS";
    };

    mountDir = lib.mkOption {
      type = lib.types.str;
      description = ''
        Directory, relative to the home directory, where an unlocked vault is
        decrypted. Must stay outside `syncDir`; asserted below. Applied by
        cryptomator.nix as `cryptomator.mountPointsDir`.
      '';
      example = "Vaults";
    };

    localRoutes = lib.mkOption {
      type = lib.types.attrsOf routeType;
      description = ''
        Friendly hostnames served by the local reverse proxy, keyed by hostname.
        Each name resolves to 127.0.0.1 through an /etc/hosts entry and is
        proxied by Caddy to `url:port`.
      '';
      example = lib.literalExpression ''
        {
          syncthing = {
            url = "http://127.0.0.1";
            port = 8384;
          };
          router = {
            url = "http://192.168.0.1";
            port = 80;
          };
        }
      '';
    };
  };

  # A mount point inside the synced folder would hand Syncthing the plaintext of
  # every unlocked vault, so such a configuration is refused rather than built.
  config.assertions = [
    {
      assertion = !overlaps cfg.syncDir cfg.mountDir;
      message = ''
        host.mountDir ("${cfg.mountDir}") and host.syncDir ("${cfg.syncDir}")
        overlap. Unlocked vaults are decrypted under mountDir, so Syncthing
        would replicate their plaintext. Pick a mount point outside the sync
        folder.
      '';
    }
    {
      assertion = !overlaps cfg.mountDir cfg.vaultDir;
      message = ''
        host.vaultDir ("${cfg.vaultDir}") and host.mountDir ("${cfg.mountDir}")
        overlap. The encrypted vaults would be shadowed by the mount whenever
        one is unlocked.
      '';
    }
    {
      assertion = !overlaps cfg.mountDir cfg.qgisDir;
      message = ''
        host.qgisDir ("${cfg.qgisDir}") and host.mountDir ("${cfg.mountDir}")
        overlap. The QGIS profiles would be shadowed by the mount whenever a
        vault is unlocked, and QGIS would build a fresh configuration in their
        place.
      '';
    }
  ];
}
