# exports.sh - meant to be sourced in .bash_profile/.zshrc

export CYPRESS_BASE=~/git/sap/arch/third_party/cypress
#export RUST_TOOLS="$HOME/.rustup/toolchains/nightly-2025-10-28-x86_64-unknown-linux-gnu/lib/rustlib/x86_64-unknown-linux-gnu/bin"
export WASI_SDK_PATH="$HOME/.local/wasi-sdk-29.0-x86_64-linux"

_path_prepend "$HOME/.local/bin"
#_path_prepend "$RUST_TOOLS"
_path_prepend "/nix/var/nix/profiles/default/bin"  # Nix path
_path_prepend "$WASI_SDK_PATH/bin"

if [ -n "${WSL_DISTRO_NAME:-}" ] && [ -d /usr/lib/wsl/lib ]; then
    _path_prepend "/usr/lib/wsl/lib"
fi

_default_runtime_dir="/run/user/$(id -u)"
if [ -d "$_default_runtime_dir" ]; then
    export XDG_RUNTIME_DIR="$_default_runtime_dir"
elif [ -z "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ] && [ -d /mnt/wslg/runtime-dir ] && [ -w /mnt/wslg/runtime-dir ]; then
    export XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir
fi

if [ -z "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ] && [ -d /mnt/wslg/runtime-dir ] && [ -w /mnt/wslg/runtime-dir ]; then
    export WAYLAND_DISPLAY=wayland-0
    export QT_QPA_PLATFORM=wayland
fi
unset _default_runtime_dir

export CASE_SENSITIVE="true"
export CIRCUIT_LIB_PATH=$CYPRESS_BASE/src/cypress_exp/llvm/test5/src/libteleport_circuit.a
export COLORTERM=truecolor
export DISABLE_AUTO_TITLE='true'
export CYPRESS=$CYPRESS_BASE/src
export PROTOS=$CYPRESS_BASE/third_party/scp-api-python
if locale -a 2>/dev/null | grep -qi '^en_US\.utf-?8$'; then
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
elif locale -a 2>/dev/null | grep -qi '^c\.utf8$'; then
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8
fi
export EDITOR="vim"
export GPG_TTY=$(tty)
_is_valid_github_token() {
    case "${1:-}" in
        ""|*[[:space:]]*) return 1 ;;
    esac
    return 0
}

_load_gh_token() {
    if env -u GITHUB_TOKEN -u GH_TOKEN gh auth token >/dev/null 2>&1; then
        env -u GITHUB_TOKEN -u GH_TOKEN gh auth token 2>/dev/null
        return 0
    fi

    env -u GITHUB_TOKEN -u GH_TOKEN gh auth status -t 2>/dev/null \
        | sed -n 's/^[[:space:]-]*Token: //p' \
        | head -n 1
}

if ! _is_valid_github_token "${GITHUB_TOKEN:-}"; then
    unset GITHUB_TOKEN
fi

if ! _is_valid_github_token "${GH_TOKEN:-}"; then
    unset GH_TOKEN
fi

if [ -z "${GITHUB_TOKEN:-}" ] && [ -n "${GH_TOKEN:-}" ]; then
    export GITHUB_TOKEN="${GH_TOKEN}"
fi

if [ -z "${GITHUB_TOKEN:-}" ] && command -v gh >/dev/null 2>&1; then
    _gh_token="$(_load_gh_token)"
    if _is_valid_github_token "$_gh_token"; then
        export GITHUB_TOKEN="$_gh_token"
    fi
    unset _gh_token
fi

if [ -z "${GH_TOKEN:-}" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
    export GH_TOKEN="${GITHUB_TOKEN}"
fi

unset -f _is_valid_github_token _load_gh_token
export PYDEVD_DISABLE_FILE_VALIDATION=1
export REPORTTIME=20
export TMPDIR=/tmp # https://github.com/dotnet/runtime/issues/3168#issuecomment-389070397
export UPLOAD_FILE_TO="transfer.sh"  # For upload-file.sh
export SYSTEMD_EDITOR=vim

export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=us-east5
export ANTHROPIC_VERTEX_PROJECT_ID="gen-lang-client-0660920503"
export ANTHROPIC_MODEL="claude-opus-4-6"
export ANTHROPIC_SMALL_FAST_MODEL="claude-haiku-4-5@20251001"
export CLAUDE_CODE_OAUTH_TOKEN=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

export PYTHONPATH=$CYPRESS:$PROTOS

_path_prepend PKG_CONFIG_PATH /usr/share/pkgconfig
_path_prepend PKG_CONFIG_PATH /usr/lib/x86_64-linux-gnu/pkgconfig

_path_prepend LD_LIBRARY_PATH "$WASI_SDK_PATH/lib"

# CUDA stuff
export CUDA_HOME=/usr/local/cuda-13.0
export CUDA_PATH=/usr/local/cuda-13.0
export PATH=/usr/local/cuda-13.0/bin:$PATH
export CUDA_COMPUTE_CAP=120

# Clean up anything we might have duplicated
_path_dedup PATH
_path_dedup LIBRARY_PATH
_path_dedup LD_LIBRARY_PATH

mkdir -p ~/.local/bin
if [ -n "${DOTFILES:-}" ] && [ -d "$DOTFILES/bin" ]; then
    ln -sf "$DOTFILES"/bin/* ~/.local/bin/ 2>/dev/null || true
fi

#export WASMTIME_HOME="$HOME/.wasmtime"
#export PATH="$WASMTIME_HOME/bin:$PATH"
