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
# Manage Determinate Nix
# ------------------------------------------------------------------------------

determinate-nix:
	curl --proto '=https' --tlsv1.2 -sSf -L \
	https://install.determinate.systems/nix | ${SHELL} -s -- install

uninstall-determinate-nix:
	/nix/nix-installer uninstall

