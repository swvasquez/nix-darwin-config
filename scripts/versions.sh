#!/usr/bin/env bash
#
# Generates a CSV of installed versions for all packages declared in
# modules/darwin.nix, including nixpkgs, brews, casks, and Mac App Store apps.
# Output format: name,version,type
#
# Usage: ./scripts/versions.sh

set -euo pipefail

DARWIN_NIX="$(dirname "$0")/../modules/darwin.nix"
OUTPUT="versions.csv"

# For brews/casks: name is always single word, strip build metadata after comma
brew_to_csv() {
  awk -v type="$1" '{sub(/,.*/, "", $2); print $1","$2","type}'
}

# For mas: name may have spaces, version is last field
mas_to_csv() {
  awk '{
    version=$(NF); name="";
    for (i=1; i<NF; i++) name=name (i>1?" ":"") $i;
    print name","version",mas"
  }'
}

export -f brew_to_csv
export -f mas_to_csv

echo "Generating versions.csv..."
echo "name,version,type" > "$OUTPUT"

# Extract nixpkgs packages (requires sudo)
echo "  nixpkgs..."
awk '/systemPackages = \[/,/\];/' "$DARWIN_NIX" \
  | grep -E '^\s+pkgs\.' \
  | grep -oE 'pkgs\.\S+' \
  | sed 's/pkgs\.//' \
  | while read -r pkg; do
      version=$(nix eval --raw "nixpkgs#${pkg}.version" 2>/dev/null || true)
      if [[ -n "$version" ]]; then
        echo "$pkg,$version,nixpkgs"
      fi
    done >> "$OUTPUT"

# Extract brew/cask/mas packages as the original user.
# Homebrew explicitly refuses to run as root, so we drop back to the invoking
# user via SUDO_USER when this script is run with sudo.
ORIGINAL_USER="${SUDO_USER:-$USER}"
sudo -u "$ORIGINAL_USER" bash -s "$DARWIN_NIX" "$OUTPUT" << 'EOF'
DARWIN_NIX="$1"
OUTPUT="$2"

brew_to_csv() {
  awk -v type="$1" '{sub(/,.*/, "", $2); print $1","$2","type}'
}

mas_to_csv() {
  awk '{
    version=$(NF); name="";
    for (i=1; i<NF; i++) name=name (i>1?" ":"") $i;
    print name","version",mas"
  }'
}

export -f brew_to_csv
export -f mas_to_csv

{
  echo "  brews..." >&2
  awk '/brews = \[/,/\];/' "$DARWIN_NIX" \
    | grep -E '^\s+"[^"]+"' \
    | tr -d '" \t' \
    | xargs brew list --versions \
    | brew_to_csv brew

  awk '/brews = \[/,/\];/' "$DARWIN_NIX" \
    | grep 'name = ' \
    | grep -oE '"[^"]+"' \
    | tr -d '"' \
    | xargs brew list --versions \
    | brew_to_csv brew

  echo "  casks..." >&2
  awk '/casks = \[/,/\];/' "$DARWIN_NIX" \
    | grep -E '^\s+"[^"]+"' \
    | tr -d '" \t' \
    | xargs brew list --cask --versions \
    | brew_to_csv cask

  echo "  mas..." >&2
  MAS_IDS=$(awk '/masApps/,/\};/' "$DARWIN_NIX" \
    | grep -oE '[0-9]{9,}')
  mas list \
    | grep -E "^($(echo "$MAS_IDS" | tr '\n' '|' | sed 's/|$//')) " \
    | awk '{$1=""; sub(/^ /, ""); print}' \
    | sed 's/ (\(.*\))$/ \1/' \
    | mas_to_csv
} >> "$OUTPUT"
EOF

echo "Written to $OUTPUT"
