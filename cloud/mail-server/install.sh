#!/bin/bash

source "$(pwd)/core/lib.sh"

# Sanity check
_checkSanity

#
# FUNCTIONS
#
function _usage() {
    echo -n "$(basename $0) [OPTION]...

Script to install a mail server with docker-mailserver.
Version $VERSION

    Options:
        -ht, --host                 Host name (eg. mail.example.com)

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
            if ! _validateHostname "$HOSTNAME"; then
                _die "Invalid hostname: $HOSTNAME"
            fi
            # Set hostname
            setHostname
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
    if [ -z "$HOSTNAME" ]; then
        _die "Host name cannot be empty."
    fi
    DOMAIN="$(echo "$HOSTNAME" | cut -d. -f2-)"
    ADMIN_EMAIL="no-reply@$DOMAIN"
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
    local ports=("25" "465" "587")
    for port in "${ports[@]}"; do
        if [[ -z $(netstat -tulpn | grep -w "$port") ]]; then
            # Port closed
            {
                _info "Opening port $port"
                ufw allow $port
                _success "Port $port opened"
            } || {
                _error "Error opening port $port"
            }
        # else
        #     # Port open
        fi
    done
    _success "Ports opened"
}

function setHostname() {
    # Set hostname for mail server
    _header "Setting hostname"
    {
        _info "Setting hostname to $HOSTNAME"
        hostnamectl set-hostname $HOSTNAME
        _success "Hostname set to $HOSTNAME"
    } || {
        _error "Error setting hostname to $HOSTNAME"
    }
    # Verify hostname
    if [ "$(hostname)" != "$HOSTNAME" ]; then
        _die "Hostname not set correctly. Expected: $HOSTNAME, Actual: $(hostname)"
    fi
}

function update() {
    _header "Updating system"
    {
        apt-get update
        apt-get upgrade -y
        _success "System updated"
    } || {
        _error "Error updating system"
    }
}

function dockerInstall() {
    # Uninstall the tech preview or beta version of Docker Desktop
    if [[ -n $(which docker) ]]; then
        _info "Docker is already installed"
    else
        _header "Installing Docker"
        {
            apt remove docker-desktop
            rm -r $HOME/.docker/desktop
            rm /usr/local/bin/com.docker.cli
            apt purge docker-desktop
            # Install Docker Engine
            cd /tmp
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            # Install Docker Compose
            apt install docker-compose
            _success "Docker installed"
        } || {
            _error "Error installing Docker"
        }
    fi
}

function install() {
    _header "Installing Docker Mailserver"
    # Check if Docker is installed
    dockerInstall
    # Pull docker-mailserver image
    {
        _info "Pulling docker-mailserver image"
        docker pull mailserver/docker-mailserver || {
            _info "Pulling docker-mailserver image failed. Trying to pull from GitHub"
            docker pull ghcr.io/docker-mailserver/docker-mailserver:edge || {
                _die "Error pulling docker-mailserver image"
            }
        }
        _success "docker-mailserver image pulled"
    } || {
        _die "Error pulling docker-mailserver image"
    }
    # Expose ports
    exposePorts
    # Configure docker-compose.yml
    {
        _info "Configuring docker-compose.yml"
        local dockerComposeFile="$(pwd)/cloud/mail-server/docker-compose.yml"
        local dockerComposeFileBackup="$(pwd)/cloud/mail-server/docker-compose.yml.bak"
        cp $dockerComposeFile $dockerComposeFileBackup
        _sed "hostname: .*" "hostname: $HOSTNAME" $dockerComposeFile
        _sed "domainname: .*" "domainname: $DOMAIN" $dockerComposeFile
        _success "docker-compose.yml configured"
    } || {
        _die "Error configuring docker-compose.yml"
    }
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
DOMAIN=$(hostname -d)
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
}

main "$@"
_debug set +x
