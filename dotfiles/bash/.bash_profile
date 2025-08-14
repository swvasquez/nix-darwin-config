# The ShellCheck disable directive applies to the entire file when placed at
# the beginning of a file.

# shellcheck disable=SC1091
[[ -f "${HOME}/.profile" ]] && . "${HOME}/.profile"

# shellcheck disable=SC1091
[[ -f "${HOME}/.bashrc" ]] && . "${HOME}/.bashrc"
