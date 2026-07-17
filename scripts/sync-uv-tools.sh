#! /usr/bin/env bash
set -euo pipefail

uv_bin() {
  if command -v uv >/dev/null 2>&1; then
    command -v uv
    return 0
  fi

  local os arch candidate
  os=$(uname -s | tr '[:upper:]' '[:lower:]')
  if [ "$os" = "darwin" ]; then
    os="macos"
  fi

  arch=$(uname -m)
  if [ "$arch" = "x86_64" ]; then
    arch="amd64"
  elif [ "$arch" = "aarch64" ] || [ "$arch" = "arm64" ]; then
    arch="arm64"
  fi

  candidate="$HOME/.dotbins/$os/$arch/bin/uv"
  if [ -x "$candidate" ]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  return 1
}

UV_BIN="$(uv_bin)" || {
  printf '%s\n' "uv is not installed. Run dotbins sync first." >&2
  exit 1
}

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VIBE_WRAPPER_LINK="$HOME/.local/bin/vibe"
VIBE_WRAPPER_TARGET="$DOTFILES_ROOT/scripts/vibe.sh"

with_vibe_wrapper_temporarily_removed() {
  local restore_wrapper=0

  if [ -L "$VIBE_WRAPPER_LINK" ] && [ "$(readlink "$VIBE_WRAPPER_LINK")" = "$VIBE_WRAPPER_TARGET" ]; then
    rm -f "$VIBE_WRAPPER_LINK"
    restore_wrapper=1
  fi

  set +e
  "$@"
  local status=$?
  set -e

  if [ "$restore_wrapper" -eq 1 ]; then
    ln -sf "$VIBE_WRAPPER_TARGET" "$VIBE_WRAPPER_LINK"
  fi

  return "$status"
}

"$UV_BIN" tool install --force --python python3.12 --with pip aider-chat@latest
"$UV_BIN" tool install agent-cli
"$UV_BIN" tool install asciinema
"$UV_BIN" tool install black
"$UV_BIN" tool install bump-my-version
"$UV_BIN" tool install clip-files
"$UV_BIN" tool install conda-lock
"$UV_BIN" tool install dotbins
"$UV_BIN" tool install dotbot
"$UV_BIN" tool install fileup
"$UV_BIN" tool install llm --with llm-gemini --with llm-anthropic --with llm-ollama
with_vibe_wrapper_temporarily_removed "$UV_BIN" tool install --python python3.12 mistral-vibe
"$UV_BIN" tool install markdown-code-runner
"$UV_BIN" tool install mypy
"$UV_BIN" tool install pre-commit --with pre-commit-uv
"$UV_BIN" tool install pygount
"$UV_BIN" tool install rsync-time-machine
"$UV_BIN" tool install ruff
"$UV_BIN" tool install smassh
"$UV_BIN" tool install tuitorial
"$UV_BIN" tool install "unidep[all]"
with_vibe_wrapper_temporarily_removed "$UV_BIN" tool upgrade --all
