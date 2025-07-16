# exports.sh - meant to be sourced in .bash_profile/.zshrc

export SAP=~/git/sap

export PATH="$HOME/.local/bin:$PATH"  # Common place, e.g., my upload-file script
export PATH="/nix/var/nix/profiles/default/bin:$PATH"  # nix path
export PYTHONPATH=$SAP/qiskit-ionq:$QCIRCUITSIM:$CYPRESS

export CYPRESS=$SAP/system_performance/third_party/cypress/cypress/src
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR="vim"
export GPG_TTY=$(tty)
#export GITHUB_TOKEN=$(gh auth token)
export QCIRCUITSIM=$SAP/system_performance/qcircuitsim
export TMPDIR=/tmp # https://github.com/dotnet/runtime/issues/3168#issuecomment-389070397
export UPLOAD_FILE_TO="transfer.sh"  # For upload-file.sh
export SYSTEMD_EDITOR=vim


_path_prepend PKG_CONFIG_PATH /usr/share/pkgconfig
_path_prepend PKG_CONFIG_PATH /usr/lib/x86_64-linux-gnu/pkgconfig

# Clean up anything we might have duplicated
_path_dedup PATH
_path_dedup LIBRARY_PATH
_path_dedup LD_LIBRARY_PATH

