#!/bin/bash

# source "../../core/lib.sh"
wget -qO- https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/core/lib.sh | bash

# Sanity check
_checkRoot

#
# FUNCTIONS
#
function _usage() {
    echo -n "$(basename $0) [OPTION]...

Script to install a mail server with mailu in a VM instance on Oracle Cloud Infrastructure
Version $VERSION

    Options:
        -ht, --host                 Host name
        -a, --admin                 Admin email address

        -h, --help                  Display this help and exit
        -v, --version               Output version information and exit

    Examples:
        $(basename $0) --help

"
    _printPoweredBy
    exit 1
}

function processArgs() {
    # Parse Arguments
    for arg in "$@"; do
        case $arg in
        -ht=* | --ht=*)
            HOSTNAME="${arg#*=}"
            ;;
        --debug)
            DEBUG=1
            ;;
        -h | --help)
            _usage
            ;;
        *)
            _usage
            ;;
        esac
    done
    [[ -z $HOSTNAME ]] && _error "Host name cannot be empty." && exit 1

    [[ -z $ADMIN_EMAIL ]] && ADMIN_EMAIL="admin@$DOMAIN"
}

function generatePassword() {
    echo "$(openssl rand -base64 12)"
}

function generateRandomString() {
    local length=$1
    if [ -z "$length" ]; then
        length=32
    fi
    local randomString=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1)
    echo $randomString
}

function exposePorts() {
    # Open ports for mail server
    _header "Opening ports"
    local ports=("25" "465" "587" "110" "143" "993" "995")
    for port in "${ports[@]}"; do
        if [[ -z $(netstat -tulpn | grep -w "$port") ]]; then
            # Port closed
            {
                _info "Opening port $port"
                ufw allow $port
                _success "Port $port opened"
            } || {
                local error_msg="Error opening port $port"
                _error "$error_msg"
                _addMessage "$error_msg" "error"
            }
        # else
        #     # Port open
        fi
    done
    _success "Ports opened"

    # Set hostname for mail server
    hostnamectl set-hostname $HOSTNAME
}

function update() {
    _header "Updating system"
    apt update -y && apt upgrade -y
    _success "System updated!"
}

function install() {
    _header "Installing"
    # Install Mailu

    # Answer questions

}

#
# MAIN
#
export LC_CTYPE=C
export LANG=C

DEBUG=0 # 1|0
_debug set -x
VERSION="0.1.0"

HOSTNAME=
IP_ADDRESS=$(_getPublicIP)
ADMIN_EMAIL=

function main() {
    [[ $# -lt 1 ]] && _usage
    # Process arguments
    processArgs "$@"

    # Update
    update

    # Install dependencies
    install

    # Send email with error messages to EMAIL
    if [[ ! -z $_errorMsgs ]]; then
        echo "There were errors during the execution of the script. Sending email to $EMAIL"
        # source "./send.sh" --to="$EMAIL" --subject="Error executing $(basename $0)" --body="$_errorMsgs"
        wget -qO- https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/cloud/mail-server/send.sh | bash --to="$EMAIL" --subject="Error executing $(basename $0)" --body="$_errorMsgs"
    fi
}

main "$@"
_debug set +x
