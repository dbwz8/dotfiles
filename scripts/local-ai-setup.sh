#!/usr/bin/env bash
# Build an isolated CUDA llama.cpp and download the configured local model.
set -euo pipefail

script_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=local-ai-common.sh
source "${script_dir}/local-ai-common.sh"

for command_name in curl git cmake nvidia-smi; do
    local_ai_require_command "${command_name}"
done

if [[ ! -d "${LOCAL_AI_LLAMA_DIR}/.git" ]]; then
    mkdir -p "$(dirname "${LOCAL_AI_LLAMA_DIR}")"
    git clone --depth 1 https://github.com/ggml-org/llama.cpp.git "${LOCAL_AI_LLAMA_DIR}"
elif [[ "${LOCAL_AI_UPDATE_LLAMA:-0}" == "1" ]]; then
    git -C "${LOCAL_AI_LLAMA_DIR}" pull --ff-only
fi

build_jobs="${LOCAL_AI_BUILD_JOBS:-$(nproc)}"
cmake -S "${LOCAL_AI_LLAMA_DIR}" -B "${LOCAL_AI_LLAMA_DIR}/build" -DCMAKE_BUILD_TYPE=Release -DGGML_CUDA=ON
cmake --build "${LOCAL_AI_LLAMA_DIR}/build" --target llama-server --parallel "${build_jobs}"

if [[ ! -x "${local_ai_server_bin}" ]]; then
    printf 'llama.cpp build completed without llama-server: %s\n' "${local_ai_server_bin}" >&2
    exit 1
fi

mkdir -p "${LOCAL_AI_MODEL_DIR}"
if [[ ! -f "${local_ai_model_path}" ]]; then
    partial_model="${local_ai_model_path}.part"
    model_url="https://huggingface.co/${LOCAL_AI_MODEL_REPO}/resolve/main/${LOCAL_AI_MODEL_FILE}?download=true"
    printf 'Downloading %s to %s (approximately 15.9 GiB).\n' "${LOCAL_AI_MODEL_REPO}" "${local_ai_model_path}"
    curl --fail --location --retry 3 --continue-at - --output "${partial_model}" "${model_url}"
    model_bytes="$(stat --format='%s' "${partial_model}")"
    minimum_bytes=$((14 * 1024 * 1024 * 1024))
    if (( model_bytes < minimum_bytes )); then
        printf 'Downloaded model is unexpectedly small (%s bytes); keeping partial file for inspection: %s\n' "${model_bytes}" "${partial_model}" >&2
        exit 1
    fi
    mv "${partial_model}" "${local_ai_model_path}"
fi

printf 'Setup complete. llama-server: %s\n' "${local_ai_server_bin}"
printf 'Model: %s\n' "${local_ai_model_path}"

local_ai_unit="${HOME}/.config/systemd/user/local-ai-glm.service"
if [[ -f "${local_ai_unit}" ]] && command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user enable --now local-ai-glm.service
    if command -v loginctl >/dev/null 2>&1 && ! loginctl enable-linger "$(id -un)"; then
        printf 'Warning: could not enable user lingering. The model will start after login, but not immediately at boot.\n' >&2
    fi
    printf 'Automatic local-ai-glm.service startup is enabled.\n'
else
    printf 'Automatic startup was not enabled because %s is not installed. Run ./install, then rerun this setup script.\n' "${local_ai_unit}" >&2
fi
