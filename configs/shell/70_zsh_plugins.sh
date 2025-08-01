# zsh_plugins.sh - meant to be sourced in .zshrc

set -o vi

if [[ ($- == *i*) && -n "$ZSH_VERSION" ]]; then
    # -- oh-my-zsh
    [[ -z $STARSHIP_SHELL ]] && export ZSH_THEME="mytheme"
    DEFAULT_USER="wecker"
    export DISABLE_AUTO_UPDATE=true  # Speedup of 40%
    plugins=( git dirhistory history sudo uv )
    command -v eza >/dev/null && zstyle ':omz:lib:directories' aliases no  # Skip aliases in directories.zsh if eza
    export ZSH=~/git/dotfiles/submodules/oh-my-zsh
    source $ZSH/oh-my-zsh.sh

    # -- zsh plugins
    source ~/git/dotfiles/submodules/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ~/git/dotfiles/submodules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

    # -- fix Atuin [Ctrl-r] key binding
    if command -v atuin &> /dev/null; then
        bindkey -M emacs '^r' atuin-search  # This again because `omz/lib/key-bindings.zsh` overwrote it
    fi
    bindkey '^[v' .describe-key-briefly # alt-v to describe any key
    bindkey '^[OA' up-line-or-search
    bindkey '^[OB' down-line-or-search

    # -- if on Linux
    if [[ "$(uname -s)" == "Linux" ]]; then
        # Provides ctrl+backspace and ctrl+delete
        # Note: in kinto.nix I remap these to Alt+Backspace and Alt+Delete
        bindkey '^H' backward-kill-word
        bindkey '^[[3;5~' kill-word
    fi

fi
