# --------------------------------------------- HEADER ---------------------------------------------
# Configure Makefile
# --------------------------------------------------------------------------------------------------

MAKEFLAGS += --make-all
SHELL := /bin/bash
.SHELLFLAGS += -o pipefail -e

# --------------------------------------------- BUILD ----------------------------------------------
# Apply nix-darwin changes
# --------------------------------------------------------------------------------------------------

build: nix-darwin versions

# --------------------------------------------- SETUP ----------------------------------------------
# Install Nix and dependencies
# --------------------------------------------------------------------------------------------------

setup: determinate-nix

# ------------------------------------------- UNINSTALL --------------------------------------------
# Uninstall Nix and dependencies
# --------------------------------------------------------------------------------------------------

uninstall: uninstall-nix-darwin uninstall-determinate-nix

# ---------------------------------------------- NIX -----------------------------------------------
# Manage Determinate Nix and nix-darwin
# --------------------------------------------------------------------------------------------------

NIX_DARWIN_VER ?= 25.11
CONFIG ?= host00

determinate-nix:
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
	| ${SHELL} -s -- install

uninstall-determinate-nix:
	/nix/nix-installer uninstall

# Rebuild using the darwin-rebuild already installed in the system profile,
# which is the version pinned by flake.lock. On a machine that has never been
# built, that binary does not exist yet, so fall back to fetching one from
# upstream for the first switch only.
nix-darwin:
	if command -v darwin-rebuild >/dev/null 2>&1; then \
		sudo darwin-rebuild switch --flake .#${CONFIG}; \
	else \
		sudo nix run nix-darwin/nix-darwin-${NIX_DARWIN_VER}#darwin-rebuild \
			-- switch --flake .#${CONFIG}; \
	fi

# Refresh flake.lock. Inputs track release branches, so this picks up upstream
# changes within the pinned release rather than moving between releases.
update:
	nix flake update

uninstall-nix-darwin:
	nix --extra-experimental-features "nix-command flakes" run nix-darwin#darwin-uninstaller

init-flake:
	nix flake init -t nix-darwin/nix-darwin-${NIX_DARWIN_VER}

# -------------------------------------------- SANDBOX ---------------------------------------------
# Run Claude Code inside a Docker Sandboxes microVM
# --------------------------------------------------------------------------------------------------

# Every target below is a literal `sbx` command line with the sandbox name
# spelled out, so a line can be pasted into a shell or a script unchanged and
# `make` stays a convenience rather than a dependency. How the sandbox is set
# up is declared in .sbx/kit/spec.yaml, not here.

# A kit only takes effect at creation, so changing it means recreating the
# sandbox. Nothing is lost: the Claude Code configuration and session history the
# kit puts under .sbx/ live on the host and outlive the sandbox. The exception is
# .sbx/kit/settings.json, which holds how the agent behaves: the kit links to it
# rather than installing a copy, so editing it takes effect at the next
# `make sbx-agent`.
#
# The denied ranges are what keeps the sandbox off the LAN: the three RFC 1918
# private blocks, RFC 3927 link-local (where cloud metadata endpoints such as
# 169.254.169.254 sit), and RFC 6598 shared address space, which Tailscale
# numbers tailnets from, then the IPv6 unique-local and link-local blocks. They
# are passed here rather than declared in the kit because a kit declares CIDR
# rules without applying them.
#
# A LAN numbered from globally routable IPv6 would still be reachable. Closing
# that means denying ::/0, which also gives up IPv6 egress — fine for a sandbox
# that only needs the web, but only if the fallback to IPv4 holds.
# Build and start the sandbox, replacing any existing one
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

# sbx keeps the OAuth token in the host keychain and seeds each new sandbox
# with a stand-in credential, so the agent starts signed in. If Claude ever
# prompts anyway, sign in at that prompt, from within the sandbox.

# Attach Claude Code to the running sandbox
sbx-agent:
	sbx run --name nix-darwin-config

# Open a login shell in the running sandbox
sbx-shell:
	sbx exec -it nix-darwin-config bash -l

# --------------------------------------------- UTILS ----------------------------------------------
# Utilities
# --------------------------------------------------------------------------------------------------

# File selection and traversal (which files, what to skip) live in
# .pre-commit-config.yaml, not here. These targets just pick which hooks run.

# Wire prek into this clone's git hooks, so every hook in
# .pre-commit-config.yaml runs on `git commit` and `git push` (once per
# clone; `make build` and the sbx kit already install the `prek` binary
# itself - this just points git at it). A hook without a `stages:` key only
# fires on `pre-commit` regardless. Using prek, not pre-commit: pre-commit's
# nixpkgs build crashes on aarch64-darwin.
hooks:
	prek install --hook-type pre-commit --hook-type pre-push

# prek's own `--all-files` only walks `git ls-files` (tracked), so an
# untracked or staged-but-uncommitted file would be invisible to it. This
# hands every hook the tracked-plus-untracked file list explicitly instead,
# so nothing has to be `git add`ed to get checked or formatted.
ALL_FILES := $(shell git ls-files --cached --others --exclude-standard)

.SILENT: check format

check:
	prek run shellcheck --files $(ALL_FILES)
	prek run jq-check --files $(ALL_FILES)
	prek run git-crypt-verify-staged --all-files
	prek run gitleaks-untracked --all-files
	prek run gitleaks-staged --all-files
	prek run gitleaks-history --all-files

# A fixer hook exits non-zero when it modifies a file (that's how prek flags
# "this needed fixing" in CI) - the leading '-' keeps that from aborting the
# remaining formatters here, since the point of `make format` is to fix
# everything in one pass, not stop at the first thing that needed fixing.
format:
	-prek run shfmt --files $(ALL_FILES)
	-prek run nixfmt --files $(ALL_FILES)
	-prek run markdownlint --files $(ALL_FILES)
	-prek run jq-format --files $(ALL_FILES)

versions:
	${SHELL} scripts/versions.sh
