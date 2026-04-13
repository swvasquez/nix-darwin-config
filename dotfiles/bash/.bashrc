# shellcheck disable=SC2148

# Add nix-darwin PATH before the interactive guard so that non-interactive and
# login shells (e.g. `bash`, `bash -l`) also have Nix binaries in PATH. This
# must remain above the interactive-only section below.
export PATH="/run/current-system/sw/bin:${PATH}"

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

# Zoxide
eval "$(zoxide init bash)"

# Starship
eval "$(starship init bash)"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

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
