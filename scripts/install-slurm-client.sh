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

sudo apt-get update
sudo apt-get install -y slurm-client
