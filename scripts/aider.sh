#!/usr/bin/env bash
# Conservative Aider entry point for the local GLM coding server.
set -euo pipefail

script_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dotfiles_root="${script_dir}/.."
health_script="${script_dir}/local-ai-server-health.sh"
profile_config="${dotfiles_root}/configs/aider/aider-local-glm.conf.yml"
model_name="${AIDER_MODEL:-glm-4.7-flash-local}"
aider_state_dir="${AIDER_STATE_DIR:-${HOME}/.local/state/local-ai-coding/aider}"

aider_bin() {
    local candidate
    for candidate in "${AIDER_BIN:-}" "$HOME/.local/bin/aider" /opt/homebrew/bin/aider /usr/local/bin/aider; do
        if [[ -n "${candidate}" && -x "${candidate}" && ! "${candidate}" -ef "$0" ]]; then
            printf '%s\n' "${candidate}"
            return 0
        fi
    done
    command -v aider 2>/dev/null || return 1
}

real_aider="$(aider_bin)" || {
    printf 'Aider is not installed. Install it with the dotfiles uv-tool workflow first.\n' >&2
    exit 1
}

case "${1:-}" in
    -h|--help|--version)
        exec "${real_aider}" "$@"
        ;;
esac

test_cmd="${AIDER_TEST_CMD:-}"
lint_cmd=""
allow_repo_root=0
passthrough=()
while (( $# )); do
    case "$1" in
        --test-cmd)
            [[ $# -ge 2 ]] || { printf '%s requires a command.\n' "$1" >&2; exit 2; }
            test_cmd="$2"
            shift 2
            ;;
        --test-cmd=*)
            test_cmd="${1#*=}"
            shift
            ;;
        --allow-repo-root)
            allow_repo_root=1
            shift
            ;;
        --)
            shift
            passthrough+=("$@")
            break
            ;;
        *)
            passthrough+=("$1")
            shift
            ;;
    esac
done

git_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    printf 'Run Aider from inside the Git repository you intend to edit.\n' >&2
    exit 2
}
working_dir="$(pwd -P)"
tracked_files="$(git -C "${git_root}" ls-files | wc -l | tr -d ' ')"
if [[ "${working_dir}" == "${git_root}" && "${tracked_files}" -gt 500 && "${allow_repo_root}" -ne 1 ]]; then
    printf 'Refusing to start at broad repository root (%s tracked files): %s\n' "${tracked_files}" "${git_root}" >&2
    printf 'Start in a focused subdirectory, or explicitly pass --allow-repo-root.\n' >&2
    exit 2
fi

"${health_script}" --models-only

project_dir="${working_dir}"
while [[ "${project_dir}" != "${git_root}" ]]; do
    if [[ -f "${project_dir}/go.mod" || -f "${project_dir}/Cargo.toml" || -f "${project_dir}/pyproject.toml" || -f "${project_dir}/pytest.ini" || -d "${project_dir}/tests" || -f "${project_dir}/package.json" ]]; then
        break
    fi
    project_dir="$(dirname "${project_dir}")"
done

if [[ -z "${test_cmd}" ]]; then
    if [[ -f "${project_dir}/go.mod" ]]; then
        test_cmd='go test ./...'
        lint_cmd='go: gofmt -w'
    elif [[ -f "${project_dir}/Cargo.toml" ]]; then
        test_cmd='cargo fmt --check && cargo test'
    elif [[ -f "${project_dir}/pyproject.toml" || -f "${project_dir}/pytest.ini" || -d "${project_dir}/tests" ]]; then
        if rg -q '^\[tool\.ruff' "${project_dir}/pyproject.toml" 2>/dev/null || [[ -f "${project_dir}/ruff.toml" ]]; then
            test_cmd='uv run ruff check . && uv run ruff format --check . && uv run pytest'
        else
            test_cmd='uv run pytest'
        fi
    elif [[ -f "${project_dir}/package.json" ]]; then
        test_cmd='npm test'
    fi
fi

if [[ -n "${test_cmd}" ]]; then
    printf 'Automatic validation after edits: %s\n' "${test_cmd}"
else
    printf 'No project test command was detected. Pass --test-cmd "COMMAND" to enable automatic tests.\n' >&2
fi
printf 'Architect proposals require your manual acceptance. Add only relevant files to Aider context.\n'

export OPENAI_API_BASE="http://127.0.0.1:8000/v1"
export OPENAI_BASE_URL="${OPENAI_API_BASE}"
export OPENAI_API_KEY="${AIDER_OPENAI_API_KEY:-dummy}"
mkdir -p "${aider_state_dir}"

aider_args=(
    --config "${profile_config}"
    --model "openai/${model_name}"
    --architect
    --no-auto-accept-architect
    --editor-model "openai/${model_name}"
    --git
    --subtree-only
    --no-auto-commits
    --no-gitignore
    --map-tokens 0
    --input-history-file "${aider_state_dir}/input.history"
    --chat-history-file "${aider_state_dir}/chat.history.md"
    --show-diffs
    --auto-lint
)
if [[ -n "${lint_cmd}" ]]; then
    aider_args+=(--lint-cmd "${lint_cmd}")
fi
if [[ -n "${test_cmd}" ]]; then
    aider_args+=(--test-cmd "${test_cmd}" --auto-test)
fi

exec "${real_aider}" "${aider_args[@]}" "${passthrough[@]}"
