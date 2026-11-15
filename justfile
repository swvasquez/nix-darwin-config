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
nix_darwin_ver := "26.05"

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
# | Sandbox — run Claude Code and Codex inside a Docker Sandboxes microVM      |
# +----------------------------------------------------------------------------+

sbx := "nix-darwin-config"

# Build the sandbox, then sign in any agent that isn't signed in yet
sbx-up: sbx-build sbx-agent-login

# Shell base plus Docker's Claude and Codex kits, then ours; v3 kits need sbx 0.51+
# Replaces any existing sandbox. Denies LAN/link-local/CGNAT ranges; IPv6 egress stays open
sbx-build:
    sbx rm --force {{ sbx }} || true
    sbx create --name {{ sbx }} \
        --kit sbx/claude-mixin --kit sbx/codex-mixin --kit ./.sbx/kit \
        --deny-network 10.0.0.0/8 \
        --deny-network 172.16.0.0/12 \
        --deny-network 192.168.0.0/16 \
        --deny-network 169.254.0.0/16 \
        --deny-network 100.64.0.0/10 \
        --deny-network fc00::/7 \
        --deny-network fe80::/10 \
        shell .

# Sign in each agent not yet signed in; logins are stored on the Mac for every sandbox
# Codex signs in on the Mac; Claude inside the sandbox, where the proxy catches it
sbx-agent-login:
    sbx secret ls 2>/dev/null | grep -qi 'openai.*oauth' || sbx secret set openai --oauth
    sbx secret ls 2>/dev/null | grep -qi 'anthropic.*oauth' || sbx exec -it {{ sbx }} bash -lc 'claude auth login'

# Open Zellij with an agent in the sandbox on the left and a host shell on the right
sbx-agent agent="claude":
    SBX_AGENT={{ quote(agent) }} zellij --layout zellij.kdl

# Open a login shell in the running sandbox
sbx-shell:
    sbx exec -it {{ sbx }} bash -l

# +----------------------------------------------------------------------------+
# | Utils — repo housekeeping: hooks, checks, formatting                       |
# +----------------------------------------------------------------------------+

all_files := `git ls-files --cached --others --exclude-standard | tr '\n' ' '`

# prek, not pre-commit: pre-commit's nixpkgs build crashes on aarch64-darwin
hooks:
    prek install --hook-type pre-commit --hook-type pre-push

@check:
    prek run shellcheck --files {{ all_files }}
    prek run hadolint --files {{ all_files }}
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
