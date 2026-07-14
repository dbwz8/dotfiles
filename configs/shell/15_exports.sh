# exports.sh - meant to be sourced in .bash_profile/.zshrc

export CYPRESS_BASE=~/git/sap/arch/third_party/cypress
#export RUST_TOOLS="$HOME/.rustup/toolchains/nightly-2025-10-28-x86_64-unknown-linux-gnu/lib/rustlib/x86_64-unknown-linux-gnu/bin"
if [ -d "$HOME/.local/wasi-sdk-29.0-x86_64-linux" ]; then
    export WASI_SDK_PATH="$HOME/.local/wasi-sdk-29.0-x86_64-linux"
fi

_path_prepend "$HOME/.local/bin"
#_path_prepend "$RUST_TOOLS"
_path_prepend "/nix/var/nix/profiles/default/bin"  # Nix path
if [ -n "${WASI_SDK_PATH:-}" ] && [ -d "$WASI_SDK_PATH/bin" ]; then
    _path_prepend "$WASI_SDK_PATH/bin"
fi

if [ -n "${WSL_DISTRO_NAME:-}" ] && [ -d /usr/lib/wsl/lib ]; then
    _path_prepend "/usr/lib/wsl/lib"
fi

export GOROOT="${GOROOT:-${DOTFILES_GO_INSTALL_ROOT:-/usr/local/go}}"
export GOPATH="${GOPATH:-$HOME/go}"
export GOBIN="${GOBIN:-$GOPATH/bin}"
export GOMODCACHE="${GOMODCACHE:-$GOPATH/pkg/mod}"
export GOCACHE="${GOCACHE:-$HOME/.cache/go-build}"
_path_prepend "$GOBIN"
_path_prepend "$GOROOT/bin"

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
export DIRENV_LOG_FORMAT=
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
export EDITOR="nvim"
export VISUAL="nvim"
export GIT_EDITOR="nvim"
export GPG_TTY=$(tty)
_is_valid_github_token() {
    case "${1:-}" in
        ""|*[[:space:]]*) return 1 ;;
    esac
    return 0
}

_load_gh_token() {
    if command -v gh >/dev/null 2>&1; then
        _gh_token="$(env -u GITHUB_TOKEN -u GH_TOKEN gh auth token 2>/dev/null)"
        if _is_valid_github_token "$_gh_token"; then
            printf '%s\n' "$_gh_token"
            unset _gh_token
            return 0
        fi

        _gh_token="$(
            env -u GITHUB_TOKEN -u GH_TOKEN gh auth status -t 2>/dev/null \
                | sed -n 's/^[[:space:]-]*Token: //p' \
                | head -n 1
        )"
        if _is_valid_github_token "$_gh_token"; then
            printf '%s\n' "$_gh_token"
            unset _gh_token
            return 0
        fi
        unset _gh_token
    fi

    _gh_hosts_file="${GH_CONFIG_DIR:-$HOME/.config/gh}/hosts.yml"
    if [ -r "$_gh_hosts_file" ]; then
        _gh_token="$(sed -n 's/^[[:space:]]*oauth_token:[[:space:]]*//p' "$_gh_hosts_file" | head -n 1)"
        if _is_valid_github_token "$_gh_token"; then
            printf '%s\n' "$_gh_token"
            unset _gh_token _gh_hosts_file
            return 0
        fi
    fi

    unset _gh_token _gh_hosts_file
    return 1
}

if ! _is_valid_github_token "${GITHUB_TOKEN:-}"; then
    unset GITHUB_TOKEN
fi

if ! _is_valid_github_token "${GH_TOKEN:-}"; then
    unset GH_TOKEN
fi

if ! _is_valid_github_token "${GITHUB_PAT_TOKEN:-}"; then
    unset GITHUB_PAT_TOKEN
fi

if [ -z "${GITHUB_TOKEN:-}" ] && [ -n "${GH_TOKEN:-}" ]; then
    export GITHUB_TOKEN="${GH_TOKEN}"
fi

if [ -z "${GITHUB_TOKEN:-}" ] && [ -n "${GITHUB_PAT_TOKEN:-}" ]; then
    export GITHUB_TOKEN="${GITHUB_PAT_TOKEN}"
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
    _gh_token="$(_load_gh_token)"
    if _is_valid_github_token "$_gh_token"; then
        export GITHUB_TOKEN="$_gh_token"
    fi
    unset _gh_token
fi

if [ -z "${GH_TOKEN:-}" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
    export GH_TOKEN="${GITHUB_TOKEN}"
fi

if [ -z "${GITHUB_PAT_TOKEN:-}" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
    export GITHUB_PAT_TOKEN="${GITHUB_TOKEN}"
fi

unset -f _is_valid_github_token _load_gh_token
export PYDEVD_DISABLE_FILE_VALIDATION=1
export REPORTTIME=20
if [ "$(uname -s)" != "Darwin" ]; then
    export TMPDIR=/tmp # https://github.com/dotnet/runtime/issues/3168#issuecomment-389070397
fi
export UPLOAD_FILE_TO="transfer.sh"  # For upload-file.sh
export SYSTEMD_EDITOR=nvim

#export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=us-east5
#export ANTHROPIC_VERTEX_PROJECT_ID="gen-lang-client-0660920503"
export ANTHROPIC_MODEL="claude-opus-4-6"
export ANTHROPIC_SMALL_FAST_MODEL="claude-haiku-4-5@20251001"
export CLAUDE_CODE_OAUTH_TOKEN=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

export PYTHONPATH=$CYPRESS:$PROTOS

if [ -d /usr/share/pkgconfig ]; then
    _path_prepend PKG_CONFIG_PATH /usr/share/pkgconfig
fi
if [ -d /usr/lib/x86_64-linux-gnu/pkgconfig ]; then
    _path_prepend PKG_CONFIG_PATH /usr/lib/x86_64-linux-gnu/pkgconfig
fi

if [ -n "${WASI_SDK_PATH:-}" ] && [ -d "$WASI_SDK_PATH/lib" ]; then
    _path_prepend LD_LIBRARY_PATH "$WASI_SDK_PATH/lib"
fi

# CUDA stuff
if [ -d /usr/local/cuda-12.8 ]; then
    export CUDA_HOME=/usr/local/cuda-12.8
    export CUDA_PATH=/usr/local/cuda-12.8
    export PATH=/usr/local/cuda-12.8/bin:$PATH
    export CUDA_COMPUTE_CAP=120
fi

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
