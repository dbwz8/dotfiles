#!/usr/bin/env bash
set -euo pipefail

# Check if install mode is enabled
INSTALL_MODE=${1:-}

echo "📶 Connected to $(hostname)"
cd dotfiles || { echo "❌ Error: dotfiles directory not found"; exit 1; }
echo "📡 Pulling latest changes..."
git pull --autostash
echo "📦 Updating submodules..."
git submodule sync --recursive
git submodule update --recursive --init --remote --jobs 8

dotbins_bin() {
  if command -v dotbins >/dev/null 2>&1; then
    command -v dotbins
    return 0
  fi

  if [ -x "$HOME/.local/bin/dotbins" ]; then
    printf '%s\n' "$HOME/.local/bin/dotbins"
    return 0
  fi

  return 1
}

dotbins_sync_current() {
  local dotbins_bin
  dotbins_bin="$1"

  if [ "$(uname -s)" = "Darwin" ]; then
    # eza has no upstream macOS release asset; the Brewfile installs it instead.
    "$dotbins_bin" sync --current \
      delta duf dust fd gh git-lfs hyperfine rg tree-sitter yazi zellij \
      bat direnv fzf lazygit micromamba starship zoxide atuin keychain uv
    return
  fi

  "$dotbins_bin" sync --current
}

sanitize_github_token_env() {
  case "${GITHUB_TOKEN:-}" in
    ""|*[[:space:]]*) unset GITHUB_TOKEN ;;
  esac

  case "${GH_TOKEN:-}" in
    ""|*[[:space:]]*) unset GH_TOKEN ;;
  esac

  case "${GITHUB_PAT_TOKEN:-}" in
    ""|*[[:space:]]*) unset GITHUB_PAT_TOKEN ;;
  esac

  if [ -z "${GITHUB_TOKEN:-}" ] && [ -n "${GH_TOKEN:-}" ]; then
    export GITHUB_TOKEN="${GH_TOKEN}"
  fi

  if [ -z "${GITHUB_TOKEN:-}" ] && [ -n "${GITHUB_PAT_TOKEN:-}" ]; then
    export GITHUB_TOKEN="${GITHUB_PAT_TOKEN}"
  fi

  if [ -z "${GH_TOKEN:-}" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
    export GH_TOKEN="${GITHUB_TOKEN}"
  fi

  if [ -z "${GITHUB_PAT_TOKEN:-}" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
    export GITHUB_PAT_TOKEN="${GITHUB_TOKEN}"
  fi
}

sanitize_github_token_env

if DOTBINS_BIN="$(dotbins_bin)"; then
  echo "🧰 Syncing dotbins tools..."
  dotbins_sync_current "$DOTBINS_BIN"
else
  echo "⚠️ dotbins is not installed; skipping tool sync."
fi

# Only run install if INSTALL_MODE is true
if [[ "$INSTALL_MODE" == "install" ]]; then
  echo "🔄 Running install script..."
  ./install
else
  echo "⏭️ Skipping install (use 'install' parameter to run it)"
fi

echo "✅ Done!"
