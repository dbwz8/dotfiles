#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
    exit 0
fi

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BREWFILE="${DOTFILES_MACOS_BREWFILE:-$DOTFILES/configs/macos/Brewfile}"

is_disabled() {
    case "${1:-}" in
        0|false|FALSE|no|NO)
            return 0
            ;;
    esac
    return 1
}

require_command_line_tools() {
    if xcode-select -p >/dev/null 2>&1; then
        return 0
    fi

    printf '%s\n' "Xcode Command Line Tools are required before this setup can continue."
    printf '%s\n' "Starting the Apple installer. Re-run ./install after it finishes."
    xcode-select --install >/dev/null 2>&1 || true
    exit 1
}

load_homebrew_env() {
    local brew_bin

    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$brew_bin" ]; then
            eval "$("$brew_bin" shellenv)"
            return 0
        fi
    done

    return 1
}

ensure_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        eval "$(brew shellenv)"
        return 0
    fi

    if load_homebrew_env; then
        return 0
    fi

    if ! command -v curl >/dev/null 2>&1; then
        printf '%s\n' "curl is required to install Homebrew." >&2
        return 1
    fi

    printf '%s\n' "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_homebrew_env
}

install_rosetta() {
    if is_disabled "${DOTFILES_INSTALL_ROSETTA:-1}"; then
        return 0
    fi

    if [ "$(uname -m)" != "arm64" ]; then
        return 0
    fi

    if /usr/bin/arch -x86_64 /usr/bin/true >/dev/null 2>&1; then
        return 0
    fi

    printf '%s\n' "Installing Rosetta for Intel-only macOS tools..."
    if ! softwareupdate --install-rosetta --agree-to-license; then
        printf '%s\n' "Rosetta installation failed; continuing without it." >&2
    fi
}

configure_hostname() {
    local name local_name
    name="${DOTFILES_MACOS_COMPUTER_NAME:-${DOTFILES_MACOS_HOSTNAME:-}}"

    if [ -z "$name" ]; then
        return 0
    fi

    local_name="${DOTFILES_MACOS_LOCAL_HOSTNAME:-$name}"
    local_name="$(printf '%s' "$local_name" | tr -cd '[:alnum:]-')"

    if [ -z "$local_name" ]; then
        printf '%s\n' "DOTFILES_MACOS_LOCAL_HOSTNAME resolved to an empty name; skipping hostname setup." >&2
        return 0
    fi

    printf '%s\n' "Setting macOS computer name to $name..."
    sudo scutil --set HostName "$local_name"
    sudo scutil --set LocalHostName "$local_name"
    sudo scutil --set ComputerName "$name"
    dscacheutil -flushcache
}

run_brew_bundle() {
    if is_disabled "${DOTFILES_BREW_BUNDLE:-1}"; then
        return 0
    fi

    if [ ! -f "$BREWFILE" ]; then
        printf '%s\n' "Brewfile not found at $BREWFILE." >&2
        return 1
    fi

    brew update
    brew bundle --file "$BREWFILE"
}

ensure_git_lfs() {
    if command -v git >/dev/null 2>&1 && git lfs version >/dev/null 2>&1; then
        git lfs install --skip-repo
    fi
}

ensure_rustup_toolchain() {
    local rustup_bin rustup_prefix

    case "${DOTFILES_INSTALL_RUST:-auto}" in
        0|false|FALSE|no|NO)
            return 0
            ;;
    esac

    if command -v cargo >/dev/null 2>&1; then
        return 0
    fi

    if command -v rustup >/dev/null 2>&1; then
        rustup_bin="$(command -v rustup)"
    elif command -v brew >/dev/null 2>&1 && rustup_prefix="$(brew --prefix rustup 2>/dev/null)" && [ -x "$rustup_prefix/bin/rustup" ]; then
        rustup_bin="$rustup_prefix/bin/rustup"
    else
        return 0
    fi

    printf '%s\n' "Installing the default Rust toolchain with rustup..."
    "$rustup_bin" default stable
}

apply_macos_defaults() {
    if is_disabled "${DOTFILES_APPLY_MACOS_DEFAULTS:-1}"; then
        return 0
    fi

    if [ -x "$DOTFILES/configs/macos/defaults.sh" ]; then
        "$DOTFILES/configs/macos/defaults.sh"
    fi
}

require_command_line_tools
install_rosetta
configure_hostname
ensure_homebrew
run_brew_bundle
ensure_git_lfs
ensure_rustup_toolchain
apply_macos_defaults
