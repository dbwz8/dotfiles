#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname -s)" != "Linux" ]; then
    exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
    exit 0
fi

if ! command -v sudo >/dev/null 2>&1; then
    printf '%s\n' "⚠️  sudo is not available; skipping Linux package installation." >&2
    exit 0
fi

missing_packages=()
for pkg in eog adwaita-icon-theme-full neovim curl bubblewrap tree-sitter-cli build-essential pkg-config libwayland-dev libxkbcommon-dev locales; do
    if ! dpkg-query -W -f='${Status}\n' "$pkg" 2>/dev/null | grep -qx 'install ok installed'; then
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            missing_packages+=("$pkg")
        else
            printf '%s\n' "⚠️  apt package '$pkg' is unavailable; skipping." >&2
        fi
    fi
done

if [ "${#missing_packages[@]}" -ne 0 ]; then
    sudo apt-get update
    sudo apt-get install -y "${missing_packages[@]}"
fi

if ! locale -a 2>/dev/null | grep -qi '^en_US\.utf-?8$'; then
    if [ -f /etc/locale.gen ]; then
        if grep -q '^# *en_US.UTF-8 UTF-8' /etc/locale.gen; then
            sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
        elif ! grep -q '^en_US.UTF-8 UTF-8' /etc/locale.gen; then
            printf '%s\n' 'en_US.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
        fi
    fi

    if command -v locale-gen >/dev/null 2>&1; then
        sudo locale-gen en_US.UTF-8
    fi
fi

if command -v update-locale >/dev/null 2>&1; then
    sudo update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8
fi
