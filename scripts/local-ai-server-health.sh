#!/usr/bin/env bash
# Verify the configured OpenAI-compatible endpoint and a minimal completion.
set -euo pipefail

script_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=local-ai-common.sh
source "${script_dir}/local-ai-common.sh"

models_only=0
case "${1:-}" in
    --models-only)
        models_only=1
        ;;
    "")
        ;;
    *)
        printf 'usage: %s [--models-only]\n' "$0" >&2
        exit 2
        ;;
esac

local_ai_require_command curl
local_ai_require_command uv
models_json="$(curl --fail --silent --show-error --max-time 10 "${local_ai_base_url}/models")" || {
    printf 'Local AI API is unreachable at %s.\n' "${local_ai_base_url}" >&2
    exit 1
}

printf '%s' "${models_json}" | uv run --no-project python -c '
import json
import sys
expected = sys.argv[1]
payload = json.load(sys.stdin)
models = payload.get("data")
if not isinstance(models, list):
    raise SystemExit("/v1/models response has no data list")
if expected not in {item.get("id") for item in models if isinstance(item, dict)}:
    raise SystemExit(f"configured model is absent from /v1/models: {expected}")
' "${LOCAL_AI_MODEL_NAME}"

if (( models_only )); then
    printf 'Local AI API is healthy and exposes %s.\n' "${LOCAL_AI_MODEL_NAME}"
    exit 0
fi

completion_json="$(curl --fail --silent --show-error --max-time 90 \
    --header 'Content-Type: application/json' \
    --data "{\"model\":\"${LOCAL_AI_MODEL_NAME}\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with the single word ready.\"}],\"temperature\":0,\"max_tokens\":128}" \
    "${local_ai_base_url}/chat/completions")" || {
    printf 'Local AI completion request failed. Inspect %s\n' "${local_ai_log_file}" >&2
    exit 1
}

printf '%s' "${completion_json}" | uv run --no-project python -c '
import json
import sys
payload = json.load(sys.stdin)
choices = payload.get("choices")
if not isinstance(choices, list) or not choices:
    raise SystemExit("completion response has no choices")
message = choices[0].get("message")
if not isinstance(message, dict):
    raise SystemExit("completion response has no assistant message")
text = message.get("content") or message.get("reasoning_content")
if not isinstance(text, str) or not text.strip():
    raise SystemExit("completion response is empty")
'

printf 'Local AI health check passed for %s.\n' "${LOCAL_AI_MODEL_NAME}"
