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
    alias ssh-weckerAA-remote='bash "${DOTFILES:-$HOME/git/dotfiles}/scripts/reconnect-running.sh" weckerAA-remote'
    alias slurm_rsync="rsync -azvh wecker@obsidian:git/sap/qec_team/data/dbwPlay_save/'*.json' ~/git/sap/qec_team/data/dbwPlay_save"
    alias ts='tmux-start work'
    alias u='cd ..'
    alias v='nvim'
    alias vi='nvim'
    alias vim='nvim'
    alias wrap='tput smam'

    ssh() {
        local ssh_exit_status=0
        command ssh "$@" || ssh_exit_status=$?
        if [ -t 0 ] && [ -t 1 ]; then
            # A broken connection cannot relay the remote TUI's mouse cleanup.
            printf '\033[?1000l\033[?1002l\033[?1003l\033[?1004l\033[?1005l\033[?1006l\033[?1015l'
        fi
        return "$ssh_exit_status"
    }

    aider() {
        local aider_script="${DOTFILES:-$HOME/git/dotfiles}/scripts/aider.sh"
        if [ -f "$aider_script" ]; then
            "$aider_script" "$@"
        else
            command aider "$@"
        fi
    }

    zellij() {
        local zellij_tmp_base="${TMPDIR:-/tmp}/zellij-$(id -u)"
        local zellij_config_args=()
        local zellij_exit_status=0
        local zellij_boot_id=unknown
        mkdir -p "$HOME/.cache/zellij" "$HOME/.local/share/zellij"
        mkdir -p "$zellij_tmp_base/zellij-log"
        if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
            mkdir -p "$XDG_RUNTIME_DIR/zellij"
        fi
        if [ -n "${WSL_DISTRO_NAME:-}" ] && [ -f "${DOTFILES:-$HOME/git/dotfiles}/configs/zellij/config-wsl.kdl" ]; then
            zellij_config_args=(--config-dir "${DOTFILES:-$HOME/git/dotfiles}/configs/zellij" --config "${DOTFILES:-$HOME/git/dotfiles}/configs/zellij/config-wsl.kdl")
        fi
        if [ -r /proc/sys/kernel/random/boot_id ]; then
            IFS= read -r zellij_boot_id < /proc/sys/kernel/random/boot_id
        fi
        # Retain the boot ID to correlate missing exit records with WSL restarts.
        printf '%s start shell=%s boot=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$$" "$zellij_boot_id" >> "$HOME/.cache/zellij/launcher.log"
        command zellij "${zellij_config_args[@]}" "$@" || zellij_exit_status=$?
        printf '%s exit shell=%s boot=%s status=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$$" "$zellij_boot_id" "$zellij_exit_status" >> "$HOME/.cache/zellij/launcher.log"
        return "$zellij_exit_status"
    }
    alias zj='zellij'
fi
