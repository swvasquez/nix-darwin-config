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
