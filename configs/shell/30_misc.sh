# misc.sh - meant to be sourced in .bash_profile/.zshrc

# -- Homebrew (before dotbins because eza is installed by Brew on macOS)
if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# -- Atuin daemon management
# On ZFS filesystems, we need to use Atuin's daemon mode to avoid the SQLite/ZFS 
# performance bug (https://github.com/atuinsh/atuin/issues/952).
# If the Atuin daemon process is running, we point to a ZFS-specific
# config that has daemon=true enabled. This ensures that all Atuin commands
# communicate with the running daemon rather than attempting direct database access.
# The setup-atuin-daemon.sh script should be run on ZFS systems to create and 
# start the systemd service for the daemon.
#if pgrep -f "atuin daemon" > /dev/null; then
  #export ATUIN_CONFIG_DIR="$HOME/.config/atuin/zfs"
#fi

# -- Dotbins
if [ -n "$ZSH_VERSION" ] && [ -f "$HOME/.dotbins/shell/zsh.sh" ]; then
    source "$HOME/.dotbins/shell/zsh.sh"
fi
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.dotbins/shell/bash.sh" ]; then
    source "$HOME/.dotbins/shell/bash.sh"
fi
if [ -x "$HOME/.local/bin/codex" ]; then
    export PATH="$HOME/.local/bin${PATH:+":$PATH"}"
    _path_dedup PATH
fi

# -- Rust
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# -- Non-public parts
if [ -n "${DOTFILES:-}" ] && [ -f "$DOTFILES/secrets/configs/shell/main.sh" ]; then
    . "$DOTFILES/secrets/configs/shell/main.sh"
fi

# -- LM Studio CLI (lms)
if [ -f "$HOME/.lmstudio/bin/lms" ]; then
    export PATH="$PATH:$HOME/.lmstudio/bin"
fi
