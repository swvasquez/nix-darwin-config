# Packages installed into the system profile via nixpkgs, plus the nixpkgs
# settings that govern what may be installed. GUI applications generally come
# from Homebrew instead; see homebrew.nix for why.
{ pkgs, inputs, ... }:

{
  # Allow unfree software to be installed via nixpkgs
  nixpkgs.config.allowUnfree = true;

  # Use overlays to customize nixpkgs
  nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];

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
    pkgs.git-crypt
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
    pkgs.markdownlint-cli
    pkgs.moreutils
    pkgs.nodejs_22
    pkgs.nixfmt-rfc-style
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
}
