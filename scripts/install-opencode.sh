#!/usr/bin/env bash
set -euo pipefail

case "${DOTFILES_INSTALL_OPENCODE:-1}" in
    0|false|FALSE|no|NO)
        printf '%s\n' "Skipping OpenCode install because DOTFILES_INSTALL_OPENCODE=${DOTFILES_INSTALL_OPENCODE}."
        exit 0
        ;;
esac

opencode_bin() {
    local candidate
    for candidate in "${OPENCODE_BIN:-}" "$HOME/.opencode/bin/opencode" /opt/homebrew/bin/opencode /usr/local/bin/opencode; do
        if [[ -n "${candidate}" && -x "${candidate}" ]]; then
            printf '%s\n' "${candidate}"
            return 0
        fi
    done
    command -v opencode 2>/dev/null || return 1
}

if installed_opencode="$(opencode_bin)"; then
    printf '%s\n' "OpenCode already installed at ${installed_opencode}."
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    printf '%s\n' 'curl is required to install OpenCode.' >&2
    exit 1
fi

printf '%s\n' 'Installing OpenCode with the official installer...'
curl -fsSL https://opencode.ai/install | bash

if ! installed_opencode="$(opencode_bin)"; then
    printf '%s\n' 'OpenCode installation finished, but no opencode command was found.' >&2
    exit 1
fi

printf '%s\n' "OpenCode installed at ${installed_opencode}."
