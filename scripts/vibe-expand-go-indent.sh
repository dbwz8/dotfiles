#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[[ $# -eq 1 ]] || fail 'Usage: vibe-expand-go-indent <file.go>'
go_file="$1"
[[ "$go_file" == *.go ]] || fail 'vibe-expand-go-indent accepts a single .go file.'
[[ -f "$go_file" ]] || fail "Go file not found: $go_file"
[[ "$go_file" == -* ]] && go_file="./$go_file"

go_directory="$(cd -P "$(dirname "$go_file")" && pwd)"
go_basename="$(basename "$go_file")"
temporary_file="$(mktemp "${go_directory}/.${go_basename}.vibe-indent.XXXXXX")"
trap 'rm -f "$temporary_file"' EXIT

# Copying first preserves the file mode.  Only leading tab characters are
# expanded, so tabs in string literals, raw strings, and comments are intact.
cp -p "$go_file" "$temporary_file"
: >"$temporary_file"

tab=$'\t'
spaces='        '
while IFS= read -r line || [[ -n "$line" ]]; do
  leading_tabs="${line%%[!$'\t']*}"
  expanded_tabs="${leading_tabs//$tab/$spaces}"
  printf '%s%s\n' "$expanded_tabs" "${line:${#leading_tabs}}" >>"$temporary_file"
done <"$go_file"

mv -f "$temporary_file" "$go_file"
trap - EXIT
