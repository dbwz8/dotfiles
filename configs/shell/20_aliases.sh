# aliases.sh - meant to be sourced in .bash_profile/.zshrc

if [[ $- == *i* ]]; then
    # Add an "alert" alias for long running commands.  Use like so:
    #   sleep 10; alert
    alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

    alias c='code'
    alias clear=/usr/bin/clear # The one in anaconda causes multi output
    alias do_slurm='rm slurm*.out;sbatch myjob.slurm;sleep 2;jobs;sleep 2;tail -f slurm*.out'
    alias glo='git log --oneline'
    alias gs='git status'
    alias ls='eza'
    alias mm="micromamba"
    alias nowrap='tput rmam'
    alias pc='pre-commit run --all-files'
    alias p="pytest"
    alias py="python"
    alias u='cd ..'
    alias v='vim'
    alias vi='vim'
    alias wrap='tput smam'
fi
