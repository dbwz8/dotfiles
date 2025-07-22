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

function slurm_status {
    ssh obsidian '(sacct -o "JobID,Elapsed,State"|sort -r +4|(sed -u 6q;tail -n6);ls -l git/sap/qec_team/data/dbwPlay|wc -l;echo "#### TOTAL: 504 jobs,1512 runs")'
}