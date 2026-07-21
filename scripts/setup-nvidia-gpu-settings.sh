#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname -s)" != "Linux" ]; then
    exit 0
fi

if ! command -v nvidia-smi >/dev/null 2>&1; then
    exit 0
fi

if ! command -v systemctl >/dev/null 2>&1; then
    printf '%s\n' "NVIDIA GPU settings require systemd; skipping setup." >&2
    exit 0
fi

if [ "$(id -u)" -eq 0 ]; then
    SUDO=()
elif command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    SUDO=(sudo)
else
    printf '%s\n' "NVIDIA GPU settings require passwordless sudo; skipping setup." >&2
    exit 0
fi

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_SOURCE="${BASEDIR}/configs/systemd/nvidia-gpu-settings.service"
SERVICE_DESTINATION="/etc/systemd/system/nvidia-gpu-settings.service"

"${SUDO[@]}" install -Dm 644 "$SERVICE_SOURCE" "$SERVICE_DESTINATION"
"${SUDO[@]}" systemctl daemon-reload
"${SUDO[@]}" systemctl enable --now nvidia-gpu-settings.service
