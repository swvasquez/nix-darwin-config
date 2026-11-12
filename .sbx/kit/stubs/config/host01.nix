# Stand-in for the git-crypt-encrypted config/<name>.nix inside the sandbox.
# kit.yaml mounts this folder over config/ so Nix can evaluate the flake
# without the real values. Every value is fake. Keep one entry per option in
# modules/options.nix.
{
  host = {
    user = "agent";
    uid = 501;
    gitUserName = "Sandbox Stub";
    gitUserEmail = "stub@example.com";
    brewUpdates = false;
    syncDir = "Sync";
    vaultDir = "Sync/Cryptomator";
    qgisDir = "Sync/QGIS";
    mountDir = "Vaults";
    localRoutes = {
      stub = {
        url = "http://127.0.0.1";
        port = 8080;
      };
    };
  };
}
