# source "./core/lib.sh"
# Import with bash and wget
<(wget -qO- https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/core/lib.sh) | bash >/dev/null 2>&1

# Sanity check
_checkRoot
export LC_CTYPE=C
export LANG=C

function processArgs() {
    # Parse Arguments
    for arg in "$@"; do
        case $arg in
        -v=* | --value=*)
            VALUE="${arg#*=}"
            ;;
        *)
            _die "Invalid argument: $arg"
            ;;
        esac
    done
}

function main() {
    echo "Value: $VALUE"
}

main
