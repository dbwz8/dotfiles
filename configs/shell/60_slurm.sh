# slurm.sh - meant to be sourced in .bash_profile/.zshrc

if [[ $- == *i* ]] && command -v squeue &> /dev/null; then
    export SCHEDULER_SYSTEM="SLURM"
    sshnode () { ssh -o StrictHostKeyChecking=no `scontrol show node "$@" | grep NodeAddr | awk '{print $1;}' | cut -d "=" -f 2`; }

    export TMPDIR=~/.tmp/  # for VScode ssh tmp files

    function sq {
        /usr/bin/squeue -o "que:%i %10M%3D%2t %5u %15N%Z" $@
    }

    function sacct {
	if [[ -z "$@" ]];then
		/usr/bin/sacct --starttime=now-2hours --format "JobID,AllocCPUS%4,State%6,CPUTimeRaw,Elapsed,NTasks%4,NodeList%20,WorkDir%21"
	else
		/usr/bin/sacct --starttime=now-2hours --format "JobID,AllocCPUS%4,State%6,CPUTimeRaw,Elapsed,NTasks%4,NodeList%20,WorkDir%21" $@ 
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
            keepAlive+=5
            [ $keepAlive -gt 60 ] && {
                squeue -u $user
                keepAlive=0
            }
        done
    }

fi
