# misc.sh - meant to be sourced in .bash_profile/.zshrc

# -- Homebrew (before dotbins because eza is not in dotbins on MacOS)
if [ -f "/opt/homebrew/bin/brew" ]; then
   eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# -- Atuin daemon management
# On ZFS filesystems, we need to use Atuin's daemon mode to avoid the SQLite/ZFS 
# performance bug (https://github.com/atuinsh/atuin/issues/952).
# If the Atuin daemon process is running, we point to a ZFS-specific
# config that has daemon=true enabled. This ensures that all Atuin commands
# communicate with the running daemon rather than attempting direct database access.
# The setup-atuin-daemon.sh script should be run on ZFS systems to create and 
# start the systemd service for the daemon.
if pgrep -f "atuin daemon" > /dev/null; then
  export ATUIN_CONFIG_DIR="$HOME/.config/atuin/zfs"
fi

# -- Dotbins
[ -n "$ZSH_VERSION" ] && source "$HOME/.dotbins/shell/zsh.sh"
[ -n "$BASH_VERSION" ] && source "$HOME/.dotbins/shell/bash.sh"

# -- Rust
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# -- Non-public parts
if [ -f "$HOME/git/dotfiles/secrets/configs/shell/main.sh" ]; then
    . "$HOME/git/dotfiles/secrets/configs/shell/main.sh"
fi

# -- LM Studio CLI (lms)
if [ -f "$HOME/.lmstudio/bin/lms" ]; then
    export PATH="$PATH:$HOME/.lmstudio/bin"
fi
