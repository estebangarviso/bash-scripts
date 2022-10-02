#!/bin/bash
#
# Script to install and deploy portainer behind nginx reverse proxy in a docker standalone scenario.
# Only works in Linux
#
source "$(pwd)/core/lib.sh"

# Sanity check
_checkSanity

#
# FUNCTIONS
#

function _usage() {
    echo -n "$(basename $0) [OPTION]...

Script to install and deploy portainer behind nginx reverse proxy in a docker standalone scenario.
Version $VERSION

    Options:
        -n, --name                  Portainer name (default is portainer appended with a random string)
        -nrp, --nfs-remote-path     NFS mount point (default: /nfs)
        -nlp, --nfs-local-path      NFS mount point (default: /mnt/<nfs-remote-path>)
        -p, --port                  Portainer port (default: 9000)
        -h, --help                  Display this help and exit
        -v, --version               Output version information and exit

    Examples:
        $(basename $0) --help

"

}

function processArgs() {
    local defaultNfslocalpath="$NFS_LOCAL_PATH"
    for arg in "$@"; do
        case $arg in
        -d=* | --domain=*)
            DOMAIN="${arg#*=}"
            if ! _validateDomain "$DOMAIN"; then
                _die "Invalid domain: $DOMAIN"
            fi
            ;;
        -n=* | --name=*)
            PORTAINER_NAME="${arg#*=}"
            ;;
        -nrp=* | --nfs-remote-path=*)
            NFS_REMOTE_PATH="${arg#*=}"
            # Check if path begins with a slash
            if [[ "$NFS_REMOTE_PATH" != /* ]]; then
                _die "NFS remote path must begin with a slash."
            fi
            if [[ "$NFS_LOCAL_PATH" == "$defaultNfslocalpath" ]]; then
                NFS_LOCAL_PATH="/mnt${NFS_REMOTE_PATH}"
            fi
            ;;
        -nlp=* | --nfs-local-path=*)
            NFS_LOCAL_PATH="${arg#*=}"
            ;;
        -ni=* | --nfs-ip=*)
            NFS_MOUNT_IP="${arg#*=}"
            ;;
        -p=* | --port=*)
            PORTAINER_PORT="${arg#*=}"
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
    if [ -z "$NFS_MOUNT_IP" ]; then
        _die "NFS mount IP cannot be empty."
    fi
    PORTAINER_VIRTUAL_HOST="portainer$(generateRandomString 16).$DOMAIN"
    _success "Subdomain: $PORTAINER_VIRTUAL_HOST"
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

function nfsMount() {
    apt-get install -y nfs-common
    mkdir -p "${NFS_LOCAL_PATH}"
    # Check if NFS mount is already mounted
    if [[ -n $(mount | grep "$NFS_LOCAL_PATH") ]]; then
        _info "NFS mount already mounted."
    else
        # Mount NFS
        _info "Mounting NFS share $NFS_REMOTE_PATH from $NFS_MOUNT_IP to $NFS_LOCAL_PATH"
        mount "${NFS_MOUNT_IP}:${NFS_REMOTE_PATH}" "${NFS_LOCAL_PATH}" && {
            _success "NFS share mounted. Command \"mount ${NFS_MOUNT_IP}:${NFS_REMOTE_PATH} ${NFS_LOCAL_PATH}\" was successful."
        } || {
            _die "Failed to mount NFS share. Command \"mount ${NFS_MOUNT_IP}:${NFS_REMOTE_PATH} ${NFS_LOCAL_PATH}\" failed."
        }
    fi
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
    # Check if volume already exists
    if [[ -n $(docker volume ls | grep portainer_data) ]]; then
        _info "Portainer volume already exists."
    else
        # Create Portainer Volume
        _info "Creating Portainer volume..."
        docker volume create portainer_data && {
            _info "Portainer volume created."
        } || {
            _die "Failed to create Portainer volume."
        }
    fi
    # Mount Portainer Volume
    # Modify docker-compose.yml
    _info "Modifying docker-compose.yml..."
    _sed "VIRTUAL_HOST=.*" "VIRTUAL_HOST=${PORTAINER_VIRTUAL_HOST}" "${COMPOSE_FILE}"
    _sed "device:.*" "device: ${NFS_LOCAL_PATH}" "${COMPOSE_FILE}"
    _sed "o:.*" "o: addr=${NFS_MOUNT_IP}" "${COMPOSE_FILE}"
    # Verify docker-compose.yml VIRTUAL_HOST value
    _info "Verifying docker-compose.yml VIRTUAL_HOST value..."
    local vhost=$(sed -n "/- VIRTUAL_HOST=.*/p" "$COMPOSE_FILE" | sed -e 's/- VIRTUAL_HOST=//' | sed -e 's/^[ \t]*//' | sed -e 's/[ \t]*$//')
    if [[ $vhost == "$PORTAINER_VIRTUAL_HOST" ]]; then
        _success "Access Portainer at: http://$PORTAINER_VIRTUAL_HOST"
    else
        _die "docker-compose.yml VIRTUAL_HOST value verification failed, expected: $PORTAINER_VIRTUAL_HOST but got: $line"
    fi
    local device=$(sed -n "/device:.*$/p" "$COMPOSE_FILE" | sed -e 's/device: //' | sed -e 's/^[ \t]*//' | sed -e 's/[ \t]*$//')
    if [[ $device == "$NFS_LOCAL_PATH" ]]; then
        _success "NFS local path: $NFS_LOCAL_PATH"
    else
        _die "docker-compose.yml device value verification failed, expected: $NFS_LOCAL_PATH but got: $line"
    fi
    local o=$(sed -n "/o:.*$/p" "$COMPOSE_FILE" | sed -e 's/o: //' | sed -e 's/^[ \t]*//' | sed -e 's/[ \t]*$//')
    if [[ $o == "addr=$NFS_MOUNT_IP" ]]; then
        _success "NFS mount IP: $NFS_MOUNT_IP"
    else
        _die "docker-compose.yml o value verification failed, expected: addr=$NFS_MOUNT_IP but got: $line"
    fi
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
    if [[ -n $(docker service ls | grep portainer_portainer_1) ]]; then
        _success "Portainer is deployed."
    else
        _die "Portainer is not deployed."
    fi
    if [[ -n $(docker service ls | grep portainer_nginx-proxy_1) ]]; then
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
PORTAINER_VIRTUAL_HOST=
PORTAINER_PORT="9000"
COMPOSE_FILE="$(pwd)/cloud/portainer/docker-compose.yml"
NFS_REMOTE_PATH="/nfs"
NFS_LOCAL_PATH="/mnt/${NFS_REMOTE_PATH}"
NFS_MOUNT_IP=

function main() {
    [[ $# -lt 1 ]] && _usage
    # Parse arguments
    processArgs "$@"
    # Update system
    update
    # NFS Mount
    nfsMount
    # Install Docker
    installDocker
    # Install Portainer
    installPortainer
    # Deploy Portainer
    deploy
}

main "$@"

_debug set +x
