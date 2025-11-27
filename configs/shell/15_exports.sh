# exports.sh - meant to be sourced in .bash_profile/.zshrc

export SAP=~/git/sap

export WASI_SDK_PATH="$HOME/.local/wasi-sdk-29.0-x86_64-linux"

export PATH="$HOME/.local/bin:$PATH"  # Common place, e.g., my upload-file script
_path_prepend "/nix/var/nix/profiles/default/bin"  # Nix path
_path_prepend "$WASI_SDK_PATH/bin"

export CASE_SENSITIVE="true"
export CYPRESS=$SAP/system_performance/third_party/cypress/cypress/src
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR="vim"
export GPG_TTY=$(tty)
export GITHUB_TOKEN=$(gh auth token)
export PYDEVD_DISABLE_FILE_VALIDATION=1 
export QCIRCUITSIM=$SAP/system_performance/qcircuitsim
export REPORTTIME=20
export TMPDIR=/tmp # https://github.com/dotnet/runtime/issues/3168#issuecomment-389070397
export UPLOAD_FILE_TO="transfer.sh"  # For upload-file.sh
export SYSTEMD_EDITOR=vim

export PYTHONPATH=$SAP/qiskit-ionq:$QCIRCUITSIM:$CYPRESS

_path_prepend PKG_CONFIG_PATH /usr/share/pkgconfig
_path_prepend PKG_CONFIG_PATH /usr/lib/x86_64-linux-gnu/pkgconfig

_path_prepend LD_LIBRARY_PATH "$WASI_SDK_PATH/lib"

# Clean up anything we might have duplicated
_path_dedup PATH
_path_dedup LIBRARY_PATH
_path_dedup LD_LIBRARY_PATH


#export WASMTIME_HOME="$HOME/.wasmtime"
#export PATH="$WASMTIME_HOME/bin:$PATH"