# ----------------------------------- HEADER -----------------------------------
# Configure Makefile
# ------------------------------------------------------------------------------

MAKEFLAGS += --make-all
SHELL := /bin/bash
SHELLFLAGS += -o pipefail -e

# ----------------------------------- SETUP ------------------------------------
# Install Nix and dependencies
# ------------------------------------------------------------------------------

setup: determinate-nix

# --------------------------------- UNINSTALL ----------------------------------
# Uninstall Nix and dependencies
# ------------------------------------------------------------------------------

uninstall: uninstall-determinate-nix

# ------------------------------------ NIX -------------------------------------
# Manage Determinate Nix and nix-darwin
# ------------------------------------------------------------------------------

NIX_DARWIN_VER ?= 24.11

determinate-nix:
	curl --proto '=https' --tlsv1.2 -sSf -L \
	https://install.determinate.systems/nix | ${SHELL} -s -- install

uninstall-determinate-nix:
	/nix/nix-installer uninstall

init-flake:
	nix flake init -t nix-darwin/nix-darwin-${NIX_DARWIN_VER}

