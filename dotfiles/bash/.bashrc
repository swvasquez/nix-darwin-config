# shellcheck disable=SC2148

# Add nix-darwin PATH before the interactive guard so that non-interactive and
# login shells (e.g. `bash`, `bash -l`) also have Nix binaries in PATH. This
# must remain above the interactive-only section below.
export PATH="/run/current-system/sw/bin:${PATH}"

# rustup is installed via nixpkgs, so its installer never patched this file.
# The toolchain shims (rustc, cargo, rust-analyzer) land in ~/.cargo/bin. Kept
# above the interactive guard for the same reason as the line above.
export PATH="${HOME}/.cargo/bin:${PATH}"

# Commands that should be applied only for interactive shells.
[[ $- == *i* ]] || return

HISTFILESIZE=100000
HISTSIZE=10000

shopt -s histappend
shopt -s checkwinsize
shopt -s extglob
shopt -s globstar
shopt -s checkjobs

# shellcheck disable=SC1091
[[ -f ${HOME}/.bash_aliases ]] && . "${HOME}/.bash_aliases"

# ------------------------------------------------------------------------------
# Editing mode configuration
# ------------------------------------------------------------------------------

# Vi editing mode
set -o vi

# Visually indicate if in insert or normal (command) mode
bind 'set show-mode-in-prompt on'
bind 'set vi-ins-mode-string \1\e[6 q\2'
bind 'set vi-cmd-mode-string \1\e[2 q\2'

# ------------------------------------------------------------------------------
# Shell integrations
# ------------------------------------------------------------------------------
#
# When adding a new shell integration, consider the following heuristics:
#   1. If its init appends to precmd_functions or preexec_functions (Atuin
#      does), source it below bash-preexec, which is what creates those arrays.
#   2. Check whether its init prepends or appends to PROMPT_COMMAND. Prepending
#      inverts the order, so a tool sourced further down runs earlier at the
#      prompt. Zoxide and Direnv both prepend, which is why Direnv is sourced
#      last: it needs to run first, before anything else reads the environment.
#   3. Confirm its hook restores "$?" and PIPESTATUS before returning. A hook
#      that runs ahead of Starship and clobbers either breaks its status
#      modules.

# Starship
eval "$(starship init bash)"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Atuin
# shellcheck source=/dev/null
source /run/current-system/sw/share/bash/bash-preexec.sh
eval "$(atuin init bash)"

# Zoxide (needs to run after Starship integration)
eval "$(zoxide init bash)"

# Direnv (prepends to PROMPT_COMMAND; sourced last so its hook executes first)
eval "$(direnv hook bash)"

# ------------------------------------------------------------------------------
# Environment variables
# ------------------------------------------------------------------------------

export EDITOR=hx
export VISUAL=hx

# ------------------------------------------------------------------------------
# $PATH updates
# ------------------------------------------------------------------------------

export K9S_CONFIG_DIR=${HOME}/.config/k9s

# lldb-dap needed for debugging in Helix
export PATH=${PATH}:/Library/Developer/CommandLineTools/usr/bin

# ------------------------------------------------------------------------------
# User defined functions
# ------------------------------------------------------------------------------

# Activates the python virtual environment if it exists in the current directory
activate() {
	if [[ -f ".venv/bin/activate" ]]; then
		# shellcheck source=/dev/null
		source .venv/bin/activate
	else
		echo "No .venv found in $(pwd)"
	fi
}

# Downloads a YouTube video at max resolution with metadata into a UTC
# timestamped folder
yt-dlp-best() {
	yt-dlp \
		--write-info-json \
		--restrict-filenames \
		--merge-output-format mkv \
		-f "bestvideo+bestaudio" \
		-o "%(title)s-$(date -u +%Y%m%d%H%M%S)/%(title)s.%(ext)s" \
		"$1"
}

# This allows "y" to exit in the selected directory via "q"
# https://yazi-rs.github.io/docs/quick-start/#shell-wrapper
y() {
	local tempfile
	tempfile="$(mktemp -t tmp.XXXXXX)" || return

	command yazi "$@" --cwd-file="$tempfile"

	if [[ -s "$tempfile" ]] && [[ "$(cat -- "$tempfile")" != "$PWD" ]]; then
		cd -- "$(cat "$tempfile")" || return
	fi
	command rm -f -- "$tempfile" 2>/dev/null
}
