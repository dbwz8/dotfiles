# aliases.sh - meant to be sourced in .bash_profile/.zshrc

if [[ $- == *i* ]]; then
    # Add an "alert" alias for long running commands.  Use like so:
    #   sleep 10; alert
    alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

    alias c='code'
    alias clear=/usr/bin/clear # The one in anaconda causes multi output
    alias cl='claude'
    alias vcl='CLAUDE_CODE_USE_VERTEX=1 ANTHROPIC_MODEL="claude-opus-4-6" ANTHROPIC_SMALL_FAST_MODEL="claude-haiku-4-5" ANTHROPIC_VERTEX_PROJECT_ID="gen-lang-client-0660920503" claude'
    alias glo='git log --oneline --decorate -20'
    alias gs='git status'
    alias hound=' cargo run -- chat --checkpoint-dir checkpoints/holmes_sft_seed_v17_runtime_extractive_mix_from_v3base --book hound'
    alias ls='eza'
    alias mm="micromamba"
    alias nowrap='tput rmam'
    alias pc='pre-commit run --all-files'
    alias p="pytest"
    alias py="python"
    alias slurm_rsync="rsync -azvh wecker@obsidian:git/sap/qec_team/data/dbwPlay_save/'*.json' ~/git/sap/qec_team/data/dbwPlay_save"
    alias ts='tmux-start work'
    alias u='cd ..'
    alias v='nvim'
    alias vi='nvim'
    alias wrap='tput smam'

    zellij() {
        local zellij_tmp_base="${TMPDIR:-/tmp}/zellij-$(id -u)"
        local zellij_config_args=()
        mkdir -p "$HOME/.cache/zellij" "$HOME/.local/share/zellij"
        mkdir -p "$zellij_tmp_base/zellij-log"
        if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
            mkdir -p "$XDG_RUNTIME_DIR/zellij"
        fi
        if [ -n "${WSL_DISTRO_NAME:-}" ] && [ -f "${DOTFILES:-$HOME/git/dotfiles}/configs/zellij/config-wsl.kdl" ]; then
            zellij_config_args=(--config-dir "${DOTFILES:-$HOME/git/dotfiles}/configs/zellij" --config "${DOTFILES:-$HOME/git/dotfiles}/configs/zellij/config-wsl.kdl")
        fi
        command zellij "${zellij_config_args[@]}" "$@"
    }
    alias zj='zellij'
fi
