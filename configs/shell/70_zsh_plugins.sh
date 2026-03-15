# zsh_plugins.sh - meant to be sourced in .zshrc

set -o vi

if [[ ($- == *i*) && -n "$ZSH_VERSION" ]]; then
    # -- oh-my-zsh
    [[ -z $STARSHIP_SHELL ]] && export ZSH_THEME="mytheme"
    DEFAULT_USER="${DEFAULT_USER:-${USER:-}}"
    export DISABLE_AUTO_UPDATE=true  # Speedup of 40%
    plugins=( git dirhistory history sudo uv )
    command -v eza >/dev/null && zstyle ':omz:lib:directories' aliases no  # Skip aliases in directories.zsh if eza
    export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
    _dotfiles_root="${ZSH:A:h:h}"
    if [ -f "$ZSH/oh-my-zsh.sh" ]; then
        source "$ZSH/oh-my-zsh.sh"
    fi
    # Drop conflicting Oh My Zsh git alias; keep system `gcp` command available.
    (( $+aliases[gcp] )) && unalias gcp

    # -- zsh plugins
    if [ -f "$_dotfiles_root/submodules/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
        source "$_dotfiles_root/submodules/zsh-autosuggestions/zsh-autosuggestions.zsh"
    fi
    if [ -f "$_dotfiles_root/submodules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
        source "$_dotfiles_root/submodules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    fi

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

    unset _dotfiles_root

fi
