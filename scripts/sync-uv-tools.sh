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
"$UV_BIN" tool install markdown-code-runner
"$UV_BIN" tool install mypy
"$UV_BIN" tool install pre-commit --with pre-commit-uv
"$UV_BIN" tool install pygount
"$UV_BIN" tool install rsync-time-machine
"$UV_BIN" tool install ruff
"$UV_BIN" tool install smassh
"$UV_BIN" tool install tuitorial
"$UV_BIN" tool install "unidep[all]"
"$UV_BIN" tool upgrade --all
