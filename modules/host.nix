{ lib, ... }:

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
}
