# exports.sh - meant to be sourced in .bash_profile/.zshrc

export CYPRESS_BASE=~/git/sap/arch/third_party/cypress
#export RUST_TOOLS="$HOME/.rustup/toolchains/nightly-2025-10-28-x86_64-unknown-linux-gnu/lib/rustlib/x86_64-unknown-linux-gnu/bin"
export WASI_SDK_PATH="$HOME/.local/wasi-sdk-29.0-x86_64-linux"

_path_prepend "$HOME/.local/bin"
#_path_prepend "$RUST_TOOLS"
_path_prepend "/nix/var/nix/profiles/default/bin"  # Nix path
_path_prepend "$WASI_SDK_PATH/bin"

export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir
export QT_QPA_PLATFORM=wayland
  
export CASE_SENSITIVE="true"
export CIRCUIT_LIB_PATH=$CYPRESS_BASE/src/cypress_exp/llvm/test5/src/libteleport_circuit.a
export CYPRESS=$CYPRESS_BASE/src
export PROTOS=$CYPRESS_BASE/third_party/scp-api-python
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR="vim"
export GPG_TTY=$(tty)
export GITHUB_TOKEN=$(gh auth token)
export PYDEVD_DISABLE_FILE_VALIDATION=1 
export REPORTTIME=20
export TMPDIR=/tmp # https://github.com/dotnet/runtime/issues/3168#issuecomment-389070397
export UPLOAD_FILE_TO="transfer.sh"  # For upload-file.sh
export SYSTEMD_EDITOR=vim

export PYTHONPATH=$CYPRESS:$PROTOS

_path_prepend PKG_CONFIG_PATH /usr/share/pkgconfig
_path_prepend PKG_CONFIG_PATH /usr/lib/x86_64-linux-gnu/pkgconfig

_path_prepend LD_LIBRARY_PATH "$WASI_SDK_PATH/lib"

# Clean up anything we might have duplicated
_path_dedup PATH
_path_dedup LIBRARY_PATH
_path_dedup LD_LIBRARY_PATH


#export WASMTIME_HOME="$HOME/.wasmtime"
#export PATH="$WASMTIME_HOME/bin:$PATH"
