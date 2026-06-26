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
for pkg in eog adwaita-icon-theme-full neovim curl bubblewrap tree-sitter-cli build-essential pkg-config libwayland-dev libxkbcommon-dev; do
    if ! dpkg-query -W -f='${Status}\n' "$pkg" 2>/dev/null | grep -qx 'install ok installed'; then
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            missing_packages+=("$pkg")
        else
            printf '%s\n' "⚠️  apt package '$pkg' is unavailable; skipping." >&2
        fi
    fi
done

if [ "${#missing_packages[@]}" -eq 0 ]; then
    exit 0
fi

sudo apt-get update
sudo apt-get install -y "${missing_packages[@]}"
