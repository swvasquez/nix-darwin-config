# Local reverse proxy: maps friendly hostnames to services on this machine or
# devices on the LAN. Routes are declared per machine as host.localRoutes; see
# the option description in host.nix.
#
# Everything the proxy needs lives here: the generated Caddyfile, the /etc/hosts
# entries that point those names at the loopback address, the launchd daemon
# that runs Caddy, and the rotation policy for its logs.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  routes = config.host.localRoutes;

  vhost =
    name: route:
    # LAN devices served over https present self-signed certificates.
    if lib.hasPrefix "https://" route.url then
      ''
        http://${name} {
          reverse_proxy ${route.url}:${toString route.port} {
            transport http {
              tls_insecure_skip_verify
            }
          }
        }

      ''
    # Services on this machine need a rewritten Host header, as some of them
    # (Syncthing) reject requests that do not look local.
    else if lib.hasPrefix "http://127.0.0.1" route.url then
      ''
        http://${name} {
          reverse_proxy ${route.url}:${toString route.port} {
            header_up Host localhost
          }
        }

      ''
    else
      ''
        http://${name} {
          reverse_proxy ${route.url}:${toString route.port}
        }

      '';

  caddyfile = pkgs.writeText "Caddyfile" (
    ''
      {
        auto_https off
      }

    ''
    + lib.concatStrings (lib.mapAttrsToList vhost routes)
  );
in
{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    /usr/bin/sed -i "" '/# nix-local-proxy/d' /etc/hosts
    {
      ${lib.concatMapStrings (name: ''
        echo "127.0.0.1 ${name} # nix-local-proxy"
      '') (lib.attrNames routes)}
    } >> /etc/hosts
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
}
