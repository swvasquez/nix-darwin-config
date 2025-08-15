# --------------------------------------------- HEADER ---------------------------------------------
# Configure Makefile
# --------------------------------------------------------------------------------------------------

MAKEFLAGS += --make-all
SHELL := /bin/bash
SHELLFLAGS += -o pipefail -e

# --------------------------------------------- BUILD ----------------------------------------------
# Apply nix-darwin changes
# --------------------------------------------------------------------------------------------------

build: nix-darwin

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

NIX_DARWIN_VER ?= 24.11

determinate-nix:
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
	| ${SHELL} -s -- install

uninstall-determinate-nix:
	/nix/nix-installer uninstall

nix-darwin:
	nix run nix-darwin/nix-darwin-${NIX_DARWIN_VER}#darwin-rebuild -- switch --flake .#default

uninstall-nix-darwin:
	nix --extra-experimental-features "nix-command flakes" run nix-darwin#darwin-uninstaller

init-flake:
	nix flake init -t nix-darwin/nix-darwin-${NIX_DARWIN_VER}

# --------------------------------------------- UTILS ----------------------------------------------
# Utilities
# --------------------------------------------------------------------------------------------------

check: check-bash check-json

format: format-markdown format-nix format-json format-bash

format-bash: SOURCE = ${PWD}
format-bash:
	find ${SOURCE} -name "*.sh" -o -name ".bash*" -exec shfmt -w -ln bash {} \;

format-json: SOURCE = ${PWD}
format-json:
	find ${SOURCE} -name "*.json" -exec \
		sh -c 'jq . {} > {}.tmp && mv {}.tmp {} || rm {}.tmp' \; 

format-markdown:
	 find . -name '*.md' -print0 | xargs -0 markdownlint --fix

format-nix:
	 find . -name '*.nix' -print0 | xargs -0 nixfmt

check-bash: SOURCE = ${PWD}
check-bash:
	find ${SOURCE} -name "*.sh" -o -name ".bash*" -exec shellcheck -s bash {} \;

check-json: SOURCE = ${PWD}
check-json:
	find ${SOURCE} -name "*.json" -exec jq type {} 1>/dev/null \;
