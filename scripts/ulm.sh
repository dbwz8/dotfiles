#!/usr/bin/env bash
set -euo pipefail

ulm_root="${ULM_ROOT:-$HOME/git/languages/rust/ULM}"
ulm_bin="${ULM_BIN:-$ulm_root/target/release/ulm}"

if [ ! -x "$ulm_bin" ]; then
    if [ ! -f "$ulm_root/Cargo.toml" ]; then
        printf '%s\n' "ULM checkout not found: $ulm_root" >&2
        printf '%s\n' "Set ULM_ROOT to the ULM source checkout or ULM_BIN to an executable binary." >&2
        exit 1
    fi

    if ! command -v cargo >/dev/null 2>&1; then
        printf '%s\n' "cargo is required to build ULM: $ulm_bin" >&2
        exit 1
    fi

    printf '%s\n' "Building ULM release binary..." >&2
    cargo build --release --manifest-path "$ulm_root/Cargo.toml" >&2
fi

exec "$ulm_bin" "$@"
