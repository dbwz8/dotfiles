# List usb devices (arg: from specific Manufacturer)
function usbDevs {
    manuf=${1:-.}
    usb-devices | sed "H        #add line to hold space
    /T:/h                      #put START into hold space (substitute holded in)
    /I:/!d                     #clean pattern space (start next line) if not END
    x                          #put hold space into pattern space
    /Manufacturer=${manuf}/I!d #clean pattern space if it have not Manufacturer
    a --
    "
}

#############################
# 1 arg:  Prepend arg1 to the PATH variable
# 2 args: Prepend arg2 to variable arg1
#############################
function _path_prepend {
    if [ -n "$2" ]; then
        case ":$(eval "echo \$$1"):" in
        *":$2:"*) : ;;
        *) eval "export $1=$2$(eval "echo \${$1:+\":\$$1\"}")" ;;
        esac
    else
        case ":$PATH:" in
        *":$1:"*) : ;;
        *) export PATH="$1${PATH:+":$PATH"}" ;;
        esac
    fi
}

#############################
# 1 arg:  Append arg1 to the PATH variable
# 2 args: Append arg2 to variable arg1
#############################
function _path_append {
    if [ -n "$2" ]; then
        case ":$(eval "echo \$$1"):" in
        *":$2:"*) : ;;
        *) eval "export $1=$(eval "echo \${$1:+\"\$$1:\"}")$2" ;;
        esac
    else
        case ":$PATH:" in
        *":$1:"*) : ;;
        *) export PATH="${PATH:+"$PATH:"}$1" ;;
        esac
    fi
}

#############################
# 0 arg:  De-duplicate the PATH variable
# 1 args: De-dupliate arg1
#############################
function _path_dedup {
    var=${1:-PATH}
    if [[ $SHELL =~ zsh ]];then
        val=$(echo -n "${(P)var}" | awk -v RS=':' '(!a[$0]++){if(b++)printf(RS);printf($0)}')
    else
        val=$(echo -n "${var}" | awk -v RS=':' '(!a[$0]++){if(b++)printf(RS);printf($0)}')
    fi
    eval "$var=\$val"
}

#############################
# Remove dir from Path
#############################
function _path_remove {
    DIR=$1
    NEWPATH=
    OLD_IFS=$IFS
    IFS=:
    for p in $PATH; do
        if [ $p != $DIR ]; then
            NEWPATH=${NEWPATH:+$NEWPATH:}$p
        fi
    done
    IFS=$OLD_IFS
    PATH=$NEWPATH
}

function grepr {
    args=""
    while [[ $1 = -* ]]; do
        args="${args} $1"
        shift
    done
    pat=${2:-*.py}
    grep $args -n -R --include="$pat" --exclude-dir=volumes --exclude-dir=ions -e "$1" .
}

function plantuml {
    java -Djava.awt.headless=true -jar ~/kits/plantuml.jar $*
}

###################################### SLURM ####################################
unalias squeue
function squeue {
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
            echo "        a=acct i=info p=procs q=queue o=out e=err"
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
        pat2='^[^/]+(/[^ ]*)$'
        while [ 1 ]; do
            echo "================================================================================================="
            [[ $opts =~ i ]] && sinfo -h | grep -e '#' | sed 's/^/inf:           /'
            [[ $opts =~ q ]] && {
                lines=("${(@f)$(squeue -hu $user)}")
                for line in $lines; do
                    [[ ! $line =~ $pat1 ]] && continue
                    echo $line
                    [[ $line =~ $pat2 ]] && {
                        dir=${BASH_REMATCH[1]}
                        [[ $opts =~ o ]] && {
                            fil=$(ls -t $dir/*.stdout 2>/dev/null | head -1)
                            [[ -s "$fil" ]] && {
                                local curModOut=$(date --utc --reference=$fil +%s)
                                [[ $curModOut -gt $prvMod ]] && {
                                    echo "=== fil: $fil"
                                    tail -10 $fil | sed 's/^/   out:/'
                                }
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

