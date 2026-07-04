#!/usr/bin/env bash
set -euo pipefail

case "${DOTFILES_INSTALL_CLAUDE:-1}" in
    0|false|FALSE|no|NO)
        printf '%s\n' "Skipping Claude Code install because DOTFILES_INSTALL_CLAUDE=${DOTFILES_INSTALL_CLAUDE}."
        exit 0
        ;;
esac

if command -v claude >/dev/null 2>&1; then
    printf '%s\n' "Claude Code already installed at $(command -v claude)."
    exit 0
fi

if [ -x "$HOME/.local/bin/claude" ]; then
    printf '%s\n' "Claude Code already installed at $HOME/.local/bin/claude."
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    printf '%s\n' "curl is required to install Claude Code." >&2
    exit 1
fi

install_version_or_channel="${CLAUDE_INSTALL_VERSION_OR_CHANNEL:-stable}"

printf '%s\n' "Installing Claude Code with the Anthropic native installer (${install_version_or_channel})..."
curl -fsSL https://claude.ai/install.sh | bash -s "$install_version_or_channel"

if command -v claude >/dev/null 2>&1; then
    printf '%s\n' "Claude Code installed at $(command -v claude)."
    exit 0
fi

if [ -x "$HOME/.local/bin/claude" ]; then
    printf '%s\n' "Claude Code installed at $HOME/.local/bin/claude."
    exit 0
fi

printf '%s\n' "Claude Code installation finished, but no claude command was found." >&2
exit 1
