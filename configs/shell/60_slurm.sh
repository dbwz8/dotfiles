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
        opts="aiqeo"
        dir="."
        OPTIND=1
        while getopts ":aiqou:" option; do
            case "${option}" in
            a) opts=${opts/a/} ;;
            i) opts=${opts/i/} ;;
            q) opts=${opts/q/} ;;
            o) opts=${opts/o/} ;;
            u) user=$OPTARG ;;
            \?)
                echo ""
                echo "Usage: q [-t secs] [-u user] [-aiqeo]"
                echo "  -u = user to show (default=current user)"
                echo "  -* = turn off reporting that option:"
                echo "        a=acct i=info q=queue o=out"
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
        if [[ $opts =~ a ]]; then
            echo "=========================================== acct ===================================================="
            sacct -u $user
        fi
        if [[ $opts =~ [iqeo] ]]; then
            local prvMod=$(($(date --utc +%s) - 600))
            pat1='que:(\S+) .* (R|CF) '
            echo "====================================== squeue ==================================================="
            queues
            sq -hu $user
            echo "====================================== ==================================================="
            while [ 1 ]; do
                [[ $opts =~ i ]] && sinfo -h | grep -e '#' | sed 's/^/inf:           /'
                [[ $opts =~ q ]] && {
                    [[ $opts =~ o ]] && {
                        files=(/home/$user/logs/*.out)
                        for file in $files; do
                            local curModOut=$(date --utc --reference=$file +%s)
                            [[ $curModOut -gt $prvMod ]] && {
                                lines=$(tail -10 $file)
                                [[ ! -z "$lines" ]] && {
                                    echo "=== fil: $file\n$lines"
                                }
                            }
                        done
                    }
                    lines=("${(@f)$(sq -hu $user)}")
                    [[ -z $lines ]] && break
                    prvMod=$(($(date --utc +%s) - 2))
                }
                sleep 5
            done
        fi
    }

fi
