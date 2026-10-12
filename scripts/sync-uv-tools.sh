#! /usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install-timing.sh"

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

install_uv_tool() {
  local tool_name
  tool_name="$1"
  shift

  if "$UV_BIN" tool install "$@"; then
    return 0
  fi

  printf '%s\n' "Repairing the failed uv tool environment: $tool_name" >&2
  "$UV_BIN" tool uninstall "$tool_name" || true
  "$UV_BIN" tool install "$@"
}

dotfiles_timed_step "uv install: aider-chat" install_uv_tool aider-chat --force --python python3.12 --with pip aider-chat@latest
dotfiles_timed_step "uv install: agent-cli" install_uv_tool agent-cli agent-cli
dotfiles_timed_step "uv install: asciinema" install_uv_tool asciinema asciinema
dotfiles_timed_step "uv install: black" install_uv_tool black black
dotfiles_timed_step "uv install: bump-my-version" install_uv_tool bump-my-version bump-my-version
dotfiles_timed_step "uv install: clip-files" install_uv_tool clip-files clip-files
dotfiles_timed_step "uv install: conda-lock" install_uv_tool conda-lock conda-lock
dotfiles_timed_step "uv install: dotbins" install_uv_tool dotbins dotbins
dotfiles_timed_step "uv install: dotbot" install_uv_tool dotbot dotbot
dotfiles_timed_step "uv install: fileup" install_uv_tool fileup fileup
dotfiles_timed_step "uv install: llm" install_uv_tool llm llm --with llm-gemini --with llm-anthropic --with llm-ollama
dotfiles_timed_step "uv install: mistral-vibe" with_vibe_wrapper_temporarily_removed install_uv_tool mistral-vibe --python python3.12 mistral-vibe
dotfiles_timed_step "uv install: markdown-code-runner" install_uv_tool markdown-code-runner markdown-code-runner
dotfiles_timed_step "uv install: mypy" install_uv_tool mypy mypy
dotfiles_timed_step "uv install: pre-commit" install_uv_tool pre-commit pre-commit --with pre-commit-uv
dotfiles_timed_step "uv install: pygount" install_uv_tool pygount pygount
dotfiles_timed_step "uv install: rsync-time-machine" install_uv_tool rsync-time-machine rsync-time-machine
dotfiles_timed_step "uv install: ruff" install_uv_tool ruff ruff
dotfiles_timed_step "uv install: smassh" install_uv_tool smassh smassh
dotfiles_timed_step "uv install: tuitorial" install_uv_tool tuitorial tuitorial
dotfiles_timed_step "uv install: unidep" install_uv_tool unidep "unidep[all]"
dotfiles_timed_step "uv upgrade --all" with_vibe_wrapper_temporarily_removed "$UV_BIN" tool upgrade --all
