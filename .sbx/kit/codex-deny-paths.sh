#!/bin/sh
# Codex PreToolUse hook for the sandbox, run before each shell command and
# file edit. Mirrors the Read/Edit deny rules in managed-settings.json, which
# Claude enforces on its own tools while its sandbox is off. Codex has no read
# tool, so this matches paths in the command text instead. Best effort, like
# Claude's: a command that builds a path at run time gets past it.
#
# Copied to /etc/codex/hooks by kit.yaml and registered in
# codex-requirements.toml. Exit 2 blocks the call, with the reason on stderr.

set -eu

# Fail closed: a payload this can't read blocks the call rather than passing it.
input=$(cat)
if ! tool=$(printf '%s' "$input" | jq -r '.tool_name // empty') ||
	! cmd=$(printf '%s' "$input" | jq -er '.tool_input.command // empty'); then
	echo 'Blocked: the hook could not read the command.' >&2
	exit 2
fi

# An edit's command is the whole patch. Check only the paths it names, so a
# file whose contents mention a secret can still be edited.
if [ "$tool" = apply_patch ]; then
	cmd=$(printf '%s\n' "$cmd" | sed -nE 's/^\*\*\* (Add File|Update File|Delete File|Move to): //p')
fi

# One extended regex per Claude rule group, in the same order as
# managed-settings.json. Home paths match as ~/, $HOME/ or /home/agent/.
# shellcheck disable=SC2016 # literal $HOME, matched in the command text
home='(~|\$HOME|\$\{HOME\}|/home/agent)'
patterns="
${home}/\.ssh(/|\$|[^[:alnum:]_.-])
${home}/\.gnupg
${home}/\.password-store
${home}/\.aws
${home}/\.config/gcloud
${home}/\.config/gh
${home}/\.docker/config\.json
${home}/\.npmrc
${home}/\.netrc
${home}/\.claude/\.credentials\.json
${home}/\.(zsh|bash|python|psql|mysql|node_repl|sqlite)_history
${home}/\.lesshst
(^|[^[:alnum:]_.-])\.env(\.[^[:space:]]*)?([^[:alnum:]_.-]|\$)
(^|[/[:space:]\"'=])secrets/
credentials
secret
\.git/config
\.sbx/claude/(\.credentials\.json|history\.jsonl|projects/|shell-snapshots/)
\.sbx/codex/(auth\.json|history\.jsonl|sessions/)
"

# Read from a here-doc, not a pipe, so the loop runs in this shell and its
# exit ends the script.
while IFS= read -r re; do
	[ -n "$re" ] || continue
	if printf '%s' "$cmd" | grep -Eiq -- "$re"; then
		printf 'Blocked: this touches a protected path (matched %s).\n' "$re" >&2
		exit 2
	fi
done <<EOF
$patterns
EOF
