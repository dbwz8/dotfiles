# slurm.sh - meant to be sourced in .bash_profile/.zshrc

if [[ $- == *i* ]] && command -v squeue &> /dev/null; then
    export SCHEDULER_SYSTEM="SLURM"
    sshnode () { ssh -o StrictHostKeyChecking=no `scontrol show node "$@" | grep NodeAddr | awk '{print $1;}' | cut -d "=" -f 2`; }

    export TMPDIR=~/.tmp/  # for VScode ssh tmp files

    function sq {
        /usr/bin/squeue -o "que:%9i%10M%3D%2t %5u %15N%Z" $@
    }
    function sacct {
        /usr/bin/sacct --format "JobID%5,AllocCPUS%5,State%6,CPUTimeRaw,Elapsed,NTasks%4,NodeList%20,WorkDir%41" $@
    }

    #######################################
    # Show SLURM queue status for Aiida jobs
    # ARGUMENTS: [-u user] [delaySeconds=10] [aipqeo=aiqeo]
    # OUTPUTS:   Repeating queue status
    # HELP:      Give an illegal option
    #######################################
    function q {
        local OPTIND option user dir fil opts tim
        user=$USER
        opts="aiqeo"
        tim=10
        dir="."
        OPTIND=1
        while getopts ":aiqeot:u:" option; do
            case "${option}" in
            a) opts=${opts/a/} ;;
            i) opts=${opts/i/} ;;
            q) opts=${opts/q/} ;;
            e) opts=${opts/e/} ;;
            o) opts=${opts/o/} ;;
            t) tim=$OPTARG ;;
            u) user=$OPTARG ;;
            \?)
                echo ""
                echo "Usage: q [-t secs] [-u user] [-aiqeo]"
                echo "  -t = delay in secs between reports (default=10)"
                echo "  -u = user to show (default=current user)"
                echo "  -* = turn off reporting that option:"
                echo "        a=acct i=info q=queue o=out e=err"
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
            sacct -u $user --format "JobID%10,AllocCPUS%5,State,CPUTimeRaw,Elapsed,NTasks,NodeList%20,WorkDir%41" | tail -9
        fi
        if [[ $opts =~ [iqeo] ]]; then
            local prvMod=$(($(date --utc +%s) - 600))
            pat1=' (R|CF) '
                echo "====================================== squeue ==================================================="
            sq -hu $user
            while [ 1 ]; do
                echo "================================================================================================="
                [[ $opts =~ i ]] && sinfo -h | grep -e '#' | sed 's/^/inf:           /'
                [[ $opts =~ q ]] && {
                    lines=("${(@f)$(sq -hu $user)}")
                    [[ -z $lines ]] && break
                    for line in $lines; do
                        [[ ! $line =~ $pat1 ]] && continue
                        dir=/home/$user/logs
                        [[ $opts =~ o ]] && {
                            fil=$(ls -t $dir/*.stdout 2>/dev/null | head -1)
                            [[ -s "$fil" ]] && {
                                local curModOut=$(date --utc --reference=$fil +%s)
                                [[ $curModOut -gt $prvMod ]] && {
                                    echo "=== fil: $fil"
                                    tail -10 $fil | sed 's/^/   out:/'
                                }
                            }
                            [[ $opts =~ e ]] && {
                                fil=$(ls -t $dir/*.stderr 2>/dev/null | head -1)
                                [[ -s "$fil" ]] && {
                                    local curModErr=$(date --utc --reference=$fil +%s)
                                    [[ $curModErr -gt $prvMod ]] && {
                                        echo "=== fil: $fil"
                                        tail -10 $fil | sed 's/^/   out:/'
                                    }
                                }
                            }
                        }
                    done
                    prvMod=$(($(date --utc +%s) - 2))
                }
                sleep $tim
            done
        fi
    }

fi
