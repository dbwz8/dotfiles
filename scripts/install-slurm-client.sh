#!/usr/bin/env bash
set -euo pipefail

case "$(hostname -s 2>/dev/null || true)" in
    obsidian|obsidian-*)
        exit 0
        ;;
esac

if [ "$(uname -s)" != "Linux" ]; then
    exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
    exit 0
fi

if ! command -v sudo >/dev/null 2>&1; then
    printf '%s\n' "⚠️  sudo is not available; skipping slurm-client installation." >&2
    exit 0
fi

if command -v squeue >/dev/null 2>&1; then
    exit 0
fi

if ! /usr/bin/python3 -c 'import apt_pkg' >/dev/null 2>&1; then
    printf '%s\n' "⚠️  Ubuntu apt hooks are broken because /usr/bin/python3 cannot import apt_pkg; skipping slurm-client installation." >&2
    printf '%s\n' "    This usually means the system python version does not match python-apt." >&2
    if [ -x /usr/bin/python3.10 ] && /usr/bin/python3.10 -c 'import apt_pkg' >/dev/null 2>&1; then
        printf '%s\n' "    Detected a Jammy-style mismatch: /usr/bin/python3 should point to /usr/bin/python3.10." >&2
        printf '%s\n' "    Repair with: sudo ln -sf /usr/bin/python3.10 /usr/bin/python3 && sudo apt-get update && sudo apt-get install --reinstall -y python3-minimal python3 python3.10 python3.10-minimal python3-apt" >&2
    fi
    exit 0
fi

sudo apt-get update
sudo apt-get install -y slurm-client
