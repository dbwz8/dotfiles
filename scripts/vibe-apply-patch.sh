#!/usr/bin/env bash
set -euo pipefail

max_changed_lines="${VIBE_PATCH_MAX_CHANGED_LINES:-120}"
patch_file="$(mktemp)"
trap 'rm -f "$patch_file"' EXIT

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[[ "$max_changed_lines" =~ ^[0-9]+$ ]] || fail 'VIBE_PATCH_MAX_CHANGED_LINES must be a non-negative integer.'

cat >"$patch_file"
[[ -s "$patch_file" ]] || fail 'Provide a standard unified diff on standard input.'

git apply --check "$patch_file" || exit $?

file_count=0
changed_lines=0
while IFS=$'\t' read -r added removed file_name; do
  [[ "$added" =~ ^[0-9]+$ && "$removed" =~ ^[0-9]+$ ]] || fail 'Binary patches are not supported.'
  file_count=$((file_count + 1))
  changed_lines=$((changed_lines + added + removed))
done < <(git apply --numstat "$patch_file")

[[ "$file_count" -eq 1 ]] || fail 'vibe-apply-patch accepts exactly one changed file.'
[[ "$changed_lines" -le "$max_changed_lines" ]] || fail "Patch changes ${changed_lines} lines; limit is ${max_changed_lines}."

git apply --whitespace=nowarn "$patch_file"
