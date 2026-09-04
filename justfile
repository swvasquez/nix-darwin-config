# +----------------------------------------------------------------------------+
# | Header — configure justfile                                                |
# +----------------------------------------------------------------------------+

set shell := ["bash", "-eo", "pipefail", "-c"]

# +----------------------------------------------------------------------------+
# | Build — apply nix-darwin changes                                           |
# +----------------------------------------------------------------------------+

build config=default_config: (nix-darwin config) versions

# +----------------------------------------------------------------------------+
# | Setup — install Nix and dependencies                                       |
# +----------------------------------------------------------------------------+

setup: determinate-nix

# +----------------------------------------------------------------------------+
# | Uninstall — remove Nix and dependencies                                    |
# +----------------------------------------------------------------------------+

uninstall: uninstall-nix-darwin uninstall-determinate-nix

# +----------------------------------------------------------------------------+
# | Nix — manage Determinate Nix and nix-darwin                                |
# +----------------------------------------------------------------------------+

default_config := "host00"
nix_darwin_ver := "25.11"

determinate-nix:
    curl --proto '=https' --tlsv1.2 -sSf -L \
        https://install.determinate.systems/nix \
        | bash -s -- install

uninstall-determinate-nix:
    /nix/nix-installer uninstall

# Uses the pinned darwin-rebuild if present, else fetches one from upstream
nix-darwin config=default_config:
    if command -v darwin-rebuild >/dev/null 2>&1; then \
        sudo darwin-rebuild switch --flake .#{{ config }}; \
    else \
        sudo nix run nix-darwin/nix-darwin-{{ nix_darwin_ver }}#darwin-rebuild \
            -- switch --flake .#{{ config }}; \
    fi

# Refresh flake.lock (stays within the pinned release track)
update:
    nix flake update

uninstall-nix-darwin:
    nix --extra-experimental-features "nix-command flakes" \
        run nix-darwin#darwin-uninstaller

init-flake:
    nix flake init -t nix-darwin/nix-darwin-{{ nix_darwin_ver }}

# +----------------------------------------------------------------------------+
# | Sandbox — run Claude Code inside a Docker Sandboxes microVM                |
# +----------------------------------------------------------------------------+

# Denies LAN/link-local/CGNAT ranges; IPv6 egress stays open
sbx-up:
    sbx rm --force nix-darwin-config || true
    sbx create --name nix-darwin-config --kit ./.sbx/kit \
        --deny-network 10.0.0.0/8 \
        --deny-network 172.16.0.0/12 \
        --deny-network 192.168.0.0/16 \
        --deny-network 169.254.0.0/16 \
        --deny-network 100.64.0.0/10 \
        --deny-network fc00::/7 \
        --deny-network fe80::/10 \
        claude .

# Attach Claude Code to the running sandbox
sbx-agent:
    sbx run --name nix-darwin-config

# Open a login shell in the running sandbox
sbx-shell:
    sbx exec -it nix-darwin-config bash -l

# +----------------------------------------------------------------------------+
# | Utils — repo housekeeping: hooks, checks, formatting                       |
# +----------------------------------------------------------------------------+

all_files := `git ls-files --cached --others --exclude-standard | tr '\n' ' '`

# prek, not pre-commit: pre-commit's nixpkgs build crashes on aarch64-darwin
hooks:
    prek install --hook-type pre-commit --hook-type pre-push

@check:
    prek run shellcheck --files {{ all_files }}
    prek run jq-check --files {{ all_files }}
    prek run git-crypt-verify-staged --all-files
    prek run gitleaks-untracked --all-files
    prek run gitleaks-staged --all-files
    prek run gitleaks-history --all-files

# Leading '-' ignores a fixer's nonzero exit so one fix doesn't block the rest
@format:
    -prek run shfmt --files {{ all_files }}
    -prek run nixfmt --files {{ all_files }}
    -prek run just-fmt --files {{ all_files }}
    -prek run markdownlint --files {{ all_files }}
    -prek run jq-format --files {{ all_files }}

versions:
    bash scripts/versions.sh
