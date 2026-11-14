#!/usr/bin/env bash
#
# Reports whether each agent's API is reachable from the sandbox and accepts
# its login. Runs inside the sandbox, where both logins are stand-ins that the
# proxy swaps for the real ones, so `claude auth status` and `codex login
# status` always say yes. Each check is instead one free request: a model list.
#
# Installed as /usr/local/bin/sbx-status by kit.yaml, which also runs it when
# an interactive login shell starts.

set -uo pipefail

if [ -t 1 ]; then
	bold=$'\e[1m' green=$'\e[32m' red=$'\e[31m' yellow=$'\e[33m' reset=$'\e[0m'
else
	bold='' green='' red='' yellow='' reset=''
fi
yes="${green}✓${reset}"
no="${red}✗${reset}"
unknown="${yellow}?${reset}"

# Prints one result: "<mark> <check> (<detail>)", the detail optional.
line() {
	printf '  %s %s%s\n' "$1" "$2" "${3:+ ($3)}"
}

# Sends one request with the given curl arguments and reports on it. curl's
# code 000 means no response at all; any other code means the API answered.
check() {
	local name="$1" out code error
	shift
	out=$(curl -s -o /dev/null -w '%{http_code} %{errormsg}' --max-time 10 "$@")
	code=${out%% *}
	error=${out#* }

	printf '%s%s%s\n' "$bold" "$name" "$reset"
	if [ "$code" = 000 ]; then
		line "$no" reachable "$error"
		line "$unknown" authenticated
	else
		line "$yes" reachable
		case "$code" in
		2??) line "$yes" authenticated ;;
		401 | 403) line "$no" authenticated "HTTP $code" ;;
		*) line "$unknown" authenticated "HTTP $code" ;;
		esac
	fi
}

# Claude sends the stand-in token stored in its credentials file.
claude_token=$(jq -r '.claudeAiOauth.accessToken' \
	"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json")
check Claude https://api.anthropic.com/v1/models \
	-H "Authorization: Bearer $claude_token" \
	-H "anthropic-version: 2023-06-01" \
	-H "anthropic-beta: oauth-2025-04-20"

# Codex sends the stand-in token set in codex-config.toml.
codex_version=$(codex --version | awk '{print $2}')
check Codex "https://chatgpt.com/backend-api/codex/models?client_version=$codex_version" \
	-H "Authorization: Bearer oai-oat01-proxy-managed"

echo
