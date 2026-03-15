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

sanitize_github_token_env() {
  case "${GITHUB_TOKEN:-}" in
    ""|*[[:space:]]*) unset GITHUB_TOKEN ;;
  esac

  case "${GH_TOKEN:-}" in
    ""|*[[:space:]]*) unset GH_TOKEN ;;
  esac

  if [ -z "${GITHUB_TOKEN:-}" ] && [ -n "${GH_TOKEN:-}" ]; then
    export GITHUB_TOKEN="${GH_TOKEN}"
  fi
}

sanitize_github_token_env

if DOTBINS_BIN="$(dotbins_bin)"; then
  echo "🧰 Syncing dotbins tools..."
  "$DOTBINS_BIN" sync --current
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
