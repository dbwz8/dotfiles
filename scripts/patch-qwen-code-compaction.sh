#!/usr/bin/env bash
set -euo pipefail

qwen_bin="${QWEN_CODE_BIN:-$HOME/.local/lib/qwen-code/bin/qwen}"

resolve_path() {
    local source="$1" dir

    while [[ -L "${source}" ]]; do
        dir="$(cd -P "$(dirname "${source}")" && pwd)"
        source="$(readlink "${source}")"
        [[ "${source}" != /* ]] && source="${dir}/${source}"
    done

    printf '%s\n' "${source}"
}

if [[ ! -x "${qwen_bin}" ]]; then
    printf 'Qwen Code is not installed at %s; skipping compaction patch.\n' "${qwen_bin}"
    exit 0
fi

qwen_real="$(resolve_path "${qwen_bin}")"
qwen_root="$(cd -P "$(dirname "${qwen_real}")/.." && pwd)"
chunk_dir="${qwen_root}/lib/chunks"

if [[ ! -d "${chunk_dir}" ]]; then
    printf 'Qwen Code chunks directory is missing: %s\n' "${chunk_dir}" >&2
    exit 1
fi

chunk=""
match_count=0
while IFS= read -r candidate; do
    if grep -q '^var COMPACT_MAX_OUTPUT_TOKENS = ' "${candidate}"; then
        chunk="${candidate}"
        match_count=$((match_count + 1))
    fi
done < <(find "${chunk_dir}" -type f -name 'chunk-*.js' -print)

if [[ "${match_count}" -ne 1 ]]; then
    printf 'Expected one Qwen Code compaction chunk, found %s. Refusing to patch.\n' "${match_count}" >&2
    exit 1
fi

desired_budget='var COMPACT_MAX_OUTPUT_TOKENS = 6e3;'
desired_directive='var COMPRESSION_REQUEST_DIRECTIVE = "Produce only the <state_snapshot> XML. Do not reason, call tools, or add text outside it. Keep it under 3,000 tokens.";'

if grep -Fxq "${desired_budget}" "${chunk}" && grep -Fxq "${desired_directive}" "${chunk}"; then
    printf 'Qwen Code compaction safeguard is already installed.\n'
    exit 0
fi

if ! grep -Eq '^var COMPACT_MAX_OUTPUT_TOKENS = (2e4|12e3|6e3);$' "${chunk}" \
    || ! grep -q '^var SUMMARY_RESERVE = COMPACT_MAX_OUTPUT_TOKENS;$' "${chunk}" \
    || ! grep -Eq '^var COMPRESSION_REQUEST_DIRECTIVE = ("First, reason in your <analysis> block\. Then, produce the <state_snapshot> XML\."|"Produce only the <state_snapshot> XML\. Do not reason, call tools, or add text outside it\. Keep it under 3,000 tokens\.");$' "${chunk}"; then
    printf 'Qwen Code compaction implementation is not the expected version; refusing to patch %s.\n' "${chunk}" >&2
    exit 1
fi

temporary_chunk="$(mktemp "${chunk}.tmp.XXXXXX")"
trap 'rm -f "${temporary_chunk}"' EXIT
sed \
    -e 's/^var COMPACT_MAX_OUTPUT_TOKENS = \(2e4\|12e3\);$/var COMPACT_MAX_OUTPUT_TOKENS = 6e3;/' \
    -e 's|^var COMPRESSION_REQUEST_DIRECTIVE = "First, reason in your <analysis> block\. Then, produce the <state_snapshot> XML\.";$|var COMPRESSION_REQUEST_DIRECTIVE = "Produce only the <state_snapshot> XML. Do not reason, call tools, or add text outside it. Keep it under 3,000 tokens.";|' \
    "${chunk}" > "${temporary_chunk}"
mv "${temporary_chunk}" "${chunk}"
trap - EXIT

if ! grep -Fxq "${desired_budget}" "${chunk}" || ! grep -Fxq "${desired_directive}" "${chunk}"; then
    printf 'Qwen Code compaction patch verification failed.\n' >&2
    exit 1
fi

printf 'Installed concise Qwen Code compaction safeguard.\n'
