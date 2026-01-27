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
    if [[ -n ${ZSH_VERSION-} ]]; then
        val=$(echo -n "${(P)var}" | awk -v RS=':' '(!a[$0]++){if(b++)printf(RS);printf($0)}')
    else
        val=$(echo -n "${!var}" | awk -v RS=':' '(!a[$0]++){if(b++)printf(RS);printf($0)}')
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
        if [[ $args != "" ]]; then
            args="$args $1"
        else
            args="$1"
        fi
        shift
    done
    pat=${2:-*.py}
    grep $args -n -R --include="$pat" --exclude-dir=volumes --exclude-dir=ions -e "$1" .
}

function plantuml {
    java -Djava.awt.headless=true -jar ~/kits/plantuml.jar $*
}

function slurm_status {
    ssh obsidian '(squeue -u wecker;echo "Expected: 1512, data/dbwPlay: $(ls -l git/sap/qec_team/data/dbwPlay|wc -l)")'
}

function GB {
    local index count refbranch switch branch ahead behind colorline lines
    count=10
    # Auto-detect main branch
    if git rev-parse --verify origin/main >/dev/null 2>&1; then
        refbranch="origin/main"
    elif git rev-parse --verify origin/master >/dev/null 2>&1; then
        refbranch="origin/master"
    else
        refbranch="origin/main"
    fi
    switch=""
    while getopts "r:c:" option; do
        case "${option}" in
        r) refbranch=$OPTARG ;;
        c) count=$OPTARG ;;
        \?)
            echo "Usage GB [-r refbranch] [-c count] [switch]"
            echo "  -r branch  = Use refbranch as reference for output ($refbranch)"
            echo "  -c count   = How many rows ($count)"
            return
            ;;
        :)
            echo "Usage: option $OPTARG requires an argument"
            return
            ;;
        esac
    done

    shift $((OPTIND - 1))
    if [[ $# -gt 0 ]]; then
        switch=$1
    fi

    myMap() {
        gitLines=("${(@f)$(git for-each-ref --sort=-committerdate refs/heads \
            --format='%(refname:short)|%(HEAD)%(color:yellow)%(refname:short)|%(color:bold green)%(committerdate:relative)|%(color:blue)%(subject)|%(color:magenta)%(authorname)%(color:reset)' \
            --color=always --count=${count})}")
    }
    if [[ -n "$switch" ]]; then
        myMap
        index=0
        for line in "${gitLines[@]}"; do
            branch=$(echo "$line" | awk 'BEGIN { FS = "|" }; { print $1 }' | tr -d '*')
            if [[ $index == $switch ]]; then
                git switch $branch
                break
            fi
            ((index++))
        done
    fi
    myMap
    lines=("index|ahead|behind|branch|lastcommit|message|author")
    index=0
    for line in "${gitLines[@]}"; do
        branch=$(echo "$line" | awk 'BEGIN { FS = "|" }; { print $1 }' | tr -d '*')
        ahead=$(git rev-list --count "${refbranch}..${branch}")
        behind=$(git rev-list --count "${branch}..${refbranch}")
        colorline=$(echo "$line" | sed 's/^[^|]*|//')
        line=$(echo "$index|$ahead|$behind|$colorline" | awk -F'|' -vOFS='|' '{$3=substr($3,1,60)}{$5=substr($5,1,70)}1')
        lines+=("$line")
        ((index++))
    done
    tput rmam
    for line in "${lines[@]}"; do echo "$line"; done | column -ts'|' -c 79
    tput smam
}

function dump_proto {
    local file=${1:-/tmp/native.proto}
    local path=~/git/sap/scp-api/protos
    /usr/local/bin/protoc --decode=circuit.v1.MirCircuit --proto_path=$path circuit/v1/mir.proto < $file
}

function dashboard {
    {
    pushd ~/git/ionics/projects/ion-experiments2
    poe sandcastle-dashboard &
    popd
    } >/dev/null 2>&1
}

