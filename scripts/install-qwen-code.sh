#!/usr/bin/env bash
set -euo pipefail

case "${DOTFILES_INSTALL_QWEN_CODE:-1}" in
    0|false|FALSE|no|NO)
        printf '%s\n' "Skipping Qwen Code install because DOTFILES_INSTALL_QWEN_CODE=${DOTFILES_INSTALL_QWEN_CODE}."
        exit 0
        ;;
esac

installed_qwen="${QWEN_CODE_BIN:-$HOME/.local/lib/qwen-code/bin/qwen}"

restore_qwen_wrapper() {
    dotfiles_root="${DOTFILES:-}"
    if [[ -z "$dotfiles_root" && -f "$HOME/git/dotfiles/scripts/qwen.sh" ]]; then
        dotfiles_root="$HOME/git/dotfiles"
    fi

    if [[ -n "$dotfiles_root" && -f "$dotfiles_root/scripts/qwen.sh" ]]; then
        ln -sf "$dotfiles_root/scripts/qwen.sh" "$HOME/.local/bin/qwen"
    fi
}

if [ -x "$installed_qwen" ]; then
    printf '%s\n' "Qwen Code already installed at $installed_qwen."
    restore_qwen_wrapper
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    printf '%s\n' "curl is required to install Qwen Code." >&2
    exit 1
fi

printf '%s\n' "Installing Qwen Code with the official standalone installer..."
curl -fsSL https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen-standalone.sh \
    | QWEN_NO_MODIFY_PATH=1 bash -s -- --no-modify-path

if command -v qwen >/dev/null 2>&1; then
    printf '%s\n' "Qwen Code installed at $(command -v qwen)."
    restore_qwen_wrapper
    exit 0
fi

if [ -x "$installed_qwen" ]; then
    printf '%s\n' "Qwen Code installed at $installed_qwen."
    restore_qwen_wrapper
    exit 0
fi

printf '%s\n' "Qwen Code installation finished, but no qwen command was found." >&2
exit 1
