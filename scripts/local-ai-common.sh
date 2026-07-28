#!/usr/bin/env bash
# Shared settings for the local, single-user coding model scripts.
set -euo pipefail

local_ai_script_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
local_ai_default_env_file="${local_ai_script_dir}/../configs/local-ai/local-ai.env"
local_ai_env_file="${LOCAL_AI_ENV_FILE:-${HOME}/.config/local-ai-coding.env}"

if [[ -f "${local_ai_env_file}" ]]; then
    # shellcheck source=/dev/null
    source "${local_ai_env_file}"
elif [[ -f "${local_ai_default_env_file}" ]]; then
    # shellcheck source=/dev/null
    source "${local_ai_default_env_file}"
else
    printf 'Local AI environment file is missing: %s\n' "${local_ai_env_file}" >&2
    exit 1
fi

: "${LOCAL_AI_MODEL_REPO:?LOCAL_AI_MODEL_REPO must be set}"
: "${LOCAL_AI_MODEL_FILE:?LOCAL_AI_MODEL_FILE must be set}"
: "${LOCAL_AI_MODEL_NAME:?LOCAL_AI_MODEL_NAME must be set}"
: "${LOCAL_AI_HOST:?LOCAL_AI_HOST must be set}"
: "${LOCAL_AI_PORT:?LOCAL_AI_PORT must be set}"
: "${LOCAL_AI_CTX_SIZE:?LOCAL_AI_CTX_SIZE must be set}"
: "${LOCAL_AI_GPU_LAYERS:?LOCAL_AI_GPU_LAYERS must be set}"
: "${LOCAL_AI_CACHE_TYPE_K:?LOCAL_AI_CACHE_TYPE_K must be set}"
: "${LOCAL_AI_CACHE_TYPE_V:?LOCAL_AI_CACHE_TYPE_V must be set}"
: "${LOCAL_AI_PARALLEL:?LOCAL_AI_PARALLEL must be set}"
: "${LOCAL_AI_MODEL_DIR:?LOCAL_AI_MODEL_DIR must be set}"
: "${LOCAL_AI_LLAMA_DIR:?LOCAL_AI_LLAMA_DIR must be set}"
: "${LOCAL_AI_STATE_DIR:?LOCAL_AI_STATE_DIR must be set}"

local_ai_model_path="${LOCAL_AI_MODEL_DIR}/${LOCAL_AI_MODEL_FILE}"
local_ai_server_bin="${LOCAL_AI_LLAMA_DIR}/build/bin/llama-server"
local_ai_pid_file="${LOCAL_AI_STATE_DIR}/llama-server.pid"
local_ai_log_dir="${LOCAL_AI_STATE_DIR}/logs"
local_ai_log_file="${local_ai_log_dir}/llama-server.log"
local_ai_base_url="http://${LOCAL_AI_HOST}:${LOCAL_AI_PORT}/v1"

local_ai_require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'Required command is unavailable: %s\n' "$1" >&2
        return 1
    fi
}

local_ai_pid_is_server() {
    local pid="$1"
    [[ "${pid}" =~ ^[0-9]+$ ]] || return 1
    kill -0 "${pid}" 2>/dev/null || return 1
    [[ "$(basename "$(readlink "/proc/${pid}/exe" 2>/dev/null || true)")" == "llama-server" ]]
}
