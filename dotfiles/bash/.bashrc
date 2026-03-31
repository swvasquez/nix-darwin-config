# Commands that should be applied only for interactive shells.
[[ $- == *i* ]] || return

HISTFILESIZE=100000
HISTSIZE=10000

shopt -s histappend
shopt -s checkwinsize
shopt -s extglob
shopt -s globstar
shopt -s checkjobs

# Enable Starship
eval "$(starship init bash)"

# Add /opt/homebrew to path
eval "$(/opt/homebrew/bin/brew shellenv)"

# shellcheck disable=SC1091
[[ -f ${HOME}/.bash_aliases ]] && . "${HOME}/.bash_aliases"

# ------------------------------------------------------------------------------
# User defined variables
# ------------------------------------------------------------------------------

export K9S_CONFIG_DIR=${HOME}/.config/k9s

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
