#!/usr/bin/env bash
set -euo pipefail

case "${DOTFILES_INSTALL_CODEX:-1}" in
    0|false|FALSE|no|NO)
        printf '%s\n' "Skipping Codex CLI install because DOTFILES_INSTALL_CODEX=${DOTFILES_INSTALL_CODEX}."
        exit 0
        ;;
esac

install_dir="${CODEX_INSTALL_DIR:-$HOME/.local/bin}"
codex_bin="$install_dir/codex"

if [ -x "$codex_bin" ]; then
    printf '%s\n' "Codex CLI already installed at $codex_bin."
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    printf '%s\n' "curl is required to install Codex CLI." >&2
    exit 1
fi

mkdir -p "$install_dir"

printf '%s\n' "Installing Codex CLI with the OpenAI standalone installer..."
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_INSTALL_DIR="$install_dir" CODEX_NON_INTERACTIVE=1 sh

if [ ! -x "$codex_bin" ]; then
    if command -v codex >/dev/null 2>&1; then
        printf '%s\n' "Codex CLI is available at $(command -v codex)."
        exit 0
    fi

    printf '%s\n' "Codex CLI installation finished, but $codex_bin was not found." >&2
    exit 1
fi

printf '%s\n' "Codex CLI installed at $codex_bin."
