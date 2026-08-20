# --------------------------------------------- HEADER ---------------------------------------------
# Configure Makefile
# --------------------------------------------------------------------------------------------------

MAKEFLAGS += --make-all
SHELL := /bin/bash
SHELLFLAGS += -o pipefail -e

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

# Authenticate Claude Code and store the token in the sbx keychain. Needed once
# per login, not per sandbox.
# Sign in to Claude Code inside the sandbox
sbx-login:
	sbx run --name nix-darwin-config -- auth login

# Attach Claude Code to the running sandbox
sbx-agent:
	sbx run --name nix-darwin-config

# Open a login shell in the running sandbox
sbx-shell:
	sbx exec -it nix-darwin-config bash -l

# --------------------------------------------- UTILS ----------------------------------------------
# Utilities
# --------------------------------------------------------------------------------------------------

SOURCE ?= .
EXCLUDE := .sbx

# $(call walk,<root>,<pruned dirs>,<name tests>,<command>)
define walk
find $(1) \( $(foreach d,$(2),-name $(d) -o) -false \) -prune -o -type f \( $(3) \) -exec $(4) {} +
endef

check: check-bash check-json
	
format: format-markdown format-nix format-json format-bash

format-bash: FILES := -name '*.sh' -o -name '.bash*'
format-bash: CMD   := shfmt -w -ln bash
format-bash:
	$(call walk,${SOURCE},${EXCLUDE},${FILES},${CMD})

format-json: FILES := -name '*.json'
format-json: CMD   := sh -c 'for f; do jq . "$$f" | sponge "$$f"; done' sh
format-json:
	$(call walk,${SOURCE},${EXCLUDE},${FILES},${CMD})

format-markdown: FILES := -name '*.md'
format-markdown: CMD   := markdownlint --fix
format-markdown:
	$(call walk,${SOURCE},${EXCLUDE},${FILES},${CMD})

format-nix: FILES := -name '*.nix'
format-nix: CMD   := nixfmt
format-nix:
	$(call walk,${SOURCE},${EXCLUDE},${FILES},${CMD})

check-bash: FILES := -name '*.sh' -o -name '.bash*'
check-bash: CMD   := shellcheck -s bash
check-bash:
	$(call walk,${SOURCE},${EXCLUDE},${FILES},${CMD})

check-json: FILES := -name '*.json'
check-json: CMD   := sh -c 'jq type "$$@" >/dev/null' sh
check-json:
	$(call walk,${SOURCE},${EXCLUDE},${FILES},${CMD})

versions:
	${SHELL} scripts/versions.sh
