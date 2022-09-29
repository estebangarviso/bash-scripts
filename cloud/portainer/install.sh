#!/bin/bash
#
# Script to install and deploy portainer in a docker swarm scenario
# Only works in Linux
#
source "../../core/lib.sh"

# Sanity check
_checkSanity

#
# FUNCTIONS
#

function _usage() {

}

function processArgs() {
    for arg in "$@"; do
        case $arg in
        -d=* | --domain=*)
            DOMAIN="${arg#*=}"
            if ! _validateDomain "$DOMAIN"; then
                _die "Invalid domain: $DOMAIN"
            fi
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
    if [ -z "$DOMAIN" ]; then
        _die "Domain cannot be empty."
    fi
    VIRTUAL_HOST="portainer$(generateRandomString 16).$DOMAIN"
    _success "Subdomain: $VIRTUAL_HOST"
}

function update() {
    # Update system
    _info "Updating system..."
    apt update -y && {
        _info "System updated."
    } || {
        _die "Failed to update system."
    }
    apt upgrade -y && {
        _info "System upgraded."
    } || {
        _die "Failed to upgrade system."
    }
}

function installDocker() {
    _header "Installing Portainer"
    # Install Portainer
    _info "Installing dependencies..."
    apt install lsb-release ca-certificates apt-transport-https software-properties-common curl gpg -y && {
        _info "Dependencies installed."
    } || {
        _die "Failed to install dependencies."
    }
    # Add GPG key
    _info "Adding GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && {
        _info "GPG key added."
    } || {
        _die "Failed to add GPG key."
    }
    # Add repository
    _info "Adding repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null && {
        _info "Docker repository to added to /etc/apt/sources.list.d/docker.list."
    } || {
        _die "Failed to add repository to /etc/apt/sources.list.d/docker.list."
    }
    # Update system
    update
    # Install Docker
    _info "Installing Docker..."
    apt install docker-ce -y && {
        _info "Docker installed."
    } || {
        _die "Failed to install Docker."
    }
    # Check if Docker package is installed
    _info "Checking if Docker is installed..."
    if [[ -n $(which docker) ]]; then
        _success "Docker is installed."
    else
        _die "Docker is not installed."
    fi
}

function installPortainer() {
    # Install Portainer with Docker Compose
    _header "Installing Portainer with Docker Compose..."
    # Create networks
    _info "Creating networks..."
    docker network create -d overlay proxy && {
        _info "Network proxy created."
    } || {
        _die "Failed to create network proxy."
    }
    docker network create -d agent_network && {
        _info "Network agent_network created."
    } || {
        _die "Failed to create network agent_network."
    }
    # Create Portainer Volume
    _info "Creating Portainer volume..."
    docker volume create portainer_data && {
        _info "Portainer volume created."
    } || {
        _die "Failed to create Portainer volume."
    }
    # Modify docker-compose.yml
    _info "Modifying docker-compose.yml..."
    _sed "VIRTUAL_HOST=.*" "VIRTUAL_HOST=$VIRTUAL_HOST" "$COMPOSE_FILE" && {
        _info "docker-compose.yml modified."
    } || {
        _die "Failed to modify docker-compose.yml."
    }
}

function deploy() {
    # Deploy Portainer
    _header "Deploying Portainer..."
    docker stack deploy portainer -c "$COMPOSE_FILE" && {
        _info "Portainer deployed."
    } || {
        _die "Failed to deploy Portainer."
    }
    # Check if Portainer is deployed
    _info "Checking if Portainer is deployed..."
    if [[ -n $(docker service ls | grep portainer_portainer) ]]; then
        _success "Portainer is deployed."
    else
        _die "Portainer is not deployed."
    fi
    if [[ -n $(docker service ls | grep portainer_agent) ]]; then
        _success "Portainer agent is deployed."
    else
        _die "Portainer agent is not deployed."
    fi
    if [[ -n $(docker service ls | grep portainer_reverse-proxy) ]]; then
        _success "Portainer reverse-proxy is deployed."
    else
        _die "Portainer reverse-proxy is not deployed."
    fi

    _success "Portainer has been deployed."
}

function generatePassword() {
    echo "$(openssl rand -base64 12)"
}

function generateRandomString() {
    local length=${1:-32}
    local randomString=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1)
    echo $randomString
}

#
# MAIN
#
export LC_CTYPE=C
export LANG=C

DEBUG=0 # 1|0
_debug set -x
VERSION="0.1.0"
DOMAIN=
VIRTUAL_HOST=
COMPOSE_FILE="$(pwd)/cloud/portainer/docker-compose.yml"

function main() {
    [[ $# -lt 1 ]] && _usage
    # Parse arguments
    processArgs "$@"
    # Update system
    update
    # Install Docker
    installDocker
    # Install Portainer
    installPortainer
    # Deploy Portainer
    deploy
}

main "$@"

_debug set +x
