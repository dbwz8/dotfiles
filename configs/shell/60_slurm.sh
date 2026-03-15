# slurm.sh - meant to be sourced in .bash_profile/.zshrc

_obsidian_slurm() { "$@"; }
_obsidian_slurm_ssh() { command ssh obsidian "$@"; }

case "$(hostname -s 2>/dev/null || true)" in
    obsidian|obsidian-*)
        ;;
    *)
        if [ -f /tmp/slurm.conf ]; then
            mkdir -p "$HOME/.config/slurm"
            _slurm_client_conf="$HOME/.config/slurm/obsidian-client.conf"
            _slurm_tmp_conf="${_slurm_client_conf}.$$"
            sed \
                -e '/^Include \/etc\/slurm\/slurm.conf.d\/multi-cluster.conf$/d' \
                -e 's/^SlurmctldHost=obsidian$/SlurmctldHost=obsidian.ionq.net/' \
                -e 's/^AccountingStorageHost=obsidian$/AccountingStorageHost=obsidian.ionq.net/' \
                /tmp/slurm.conf > "$_slurm_tmp_conf"
            mv "$_slurm_tmp_conf" "$_slurm_client_conf"
            export OBSIDIAN_SLURM_CONF="$_slurm_client_conf"
            # Obsidian currently runs Slurm 25.05 while this machine ships a
            # 23.11 client, so interactive read-only commands are more
            # reliable when executed on the cluster over SSH.
            _obsidian_slurm() { _obsidian_slurm_ssh "$@"; }
            squeue() { _obsidian_slurm squeue "$@"; }
            sinfo() { _obsidian_slurm sinfo "$@"; }
            scontrol() { _obsidian_slurm scontrol "$@"; }
            unset _slurm_client_conf _slurm_tmp_conf
        else
            unset OBSIDIAN_SLURM_CONF
        fi
        unset SLURM_CLUSTERS
        unset SLURM_CONF_SERVER
        ;;
esac

if [[ $- == *i* ]] && [ -x /usr/bin/squeue ]; then
    export SCHEDULER_SYSTEM="SLURM"
    sshnode () { ssh -o StrictHostKeyChecking=no `scontrol show node "$@" | grep NodeAddr | awk '{print $1;}' | cut -d "=" -f 2`; }

    export TMPDIR=~/.tmp/  # for VScode ssh tmp files

    function sq {
        squeue -o "que:%i %10M%3D%2t %5u %15N%Z" $@
    }

    function sacct {
	if [[ -z "$@" ]];then
		_obsidian_slurm sacct --starttime=now-2hours --format "JobID,AllocCPUS%4,State%6,CPUTimeRaw,Elapsed,NTasks%4,NodeList%20,WorkDir%21"
	else
		_obsidian_slurm sacct --starttime=now-2hours --format "JobID,AllocCPUS%4,State%6,CPUTimeRaw,Elapsed,NTasks%4,NodeList%20,WorkDir%21" $@ 
	fi
    }

    function queues() {
        squeue "$@" | awk '
        BEGIN {
            abbrev["R"]="(Running)"
            abbrev["PD"]="(Pending)"
            abbrev["CG"]="(Completing)"
            abbrev["F"]="(Failed)"
        }
        NR>1 {a[$5]++}
        END {
            for (i in a) {
                printf "%-2s %-12s %d\n", i, abbrev[i], a[i]
            }
        }'
    }

    #######################################
    # Show SLURM queue status
    # ARGUMENTS: [-u user] [aipqeo=aiqeo]
    # OUTPUTS:   Repeating queue status
    # HELP:      Give an illegal option
    #######################################
    function q {
        local OPTIND option user dir fil opts tim
        user=$USER
        dir="."
        OPTIND=1
        tail=10
        while getopts "t:" option; do
            case "${option}" in
            t) tail=$OPTARG;;
            \?)
                echo ""
                echo "Usage: q [-t tail]"
                echo "  -t = lines to tail (default 10)"
                echo ""
                return
                ;;
            :)
                echo "Usage: option $OPTARG requires an argument"
                return
                ;;
            esac
        done
        shift $(($OPTIND - 1))
        echo "=========================================== acct ===================================================="
        sacct -u $user
        local prvMod=$(($(date --utc +%s) - 600))
        pat1='que:(\S+) .* (R|CF) '
        echo "====================================== squeue ==================================================="
        /home/scripts/resources_per_user.sh
        queues
        sq -hu $user
        echo "========================================================================================="
        keepAlive=0
        while [ 1 ]; do
            sinfo -h | grep -e '#' | sed 's/^/inf:           /'
            files=(/home/$user/logs/*.out)
            for file in $files; do
                local curModOut=$(date --utc --reference=$file +%s)
                [[ $curModOut -gt $prvMod ]] && {
                    lines=$(tail -$tail $file)
                    [[ ! -z "$lines" ]] && {
                        echo "=== fil: $file\n$lines"
                    }
                }
            done
            lines=("${(@f)$(sq -hu $user)}")
            [[ -z $lines ]] && break
            prvMod=$(($(date --utc +%s) - 2))
            sleep 5
	    ((keepAlive += 5))
        [ $keepAlive -gt 60 ] && {
            squeue -u $user
            echo "========================================================================================="
            keepAlive=0
        }
        done
    }

fi
