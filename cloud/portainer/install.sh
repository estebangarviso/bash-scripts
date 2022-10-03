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
        -d, --domain                                    Domain name (mandatory)
        -nprp, --nfs-portainer-remote-path              NFS portainer remote path (default: /portainer)
        -nplp, --nfs-portainer-local-path               NFS portainer local path (default: /nfs/portainer)
        -nnpmrp, --nfs-nginx-proxy-manager-remote-path  NFS nginx proxy manager remote path (default: /nginx-proxy-manager)
        -nnpmplp, --nfs-nginx-proxy-manager-local-path  NFS nginx proxy manager local path (default: /nfs/nginx-proxy-manager)
        -na, --nfs-address                              NFS address, it can be an IP or FQDN (mandatory)
        -pp, --portainer-port                           Portainer port (default: 9000)
        -h, --help                                      Display this help and exit
        -v, --version                                   Output version information and exit

    Examples:
        $(basename $0) --help

"

}

function processArgs() {
    local defaultPortainerNfslocalpath="$NFS_PORTAINER_LOCAL_PATH"
    local defaultNginxProxyManagerNfslocalpath="$NFS_NGINX_PROXY_MANAGER_LOCAL_PATH"
    for arg in "$@"; do
        case $arg in
        -d=* | --domain=*)
            DOMAIN="${arg#*=}"
            if ! _validateDomain "$DOMAIN"; then
                _die "Invalid domain: $DOMAIN"
            fi
            ;;
        -nprp=* | --nfs-portainer-remote-path=*)
            NFS_PORTAINER_REMOTE_PATH="${arg#*=}"
            # Check if path begins with a slash
            if [[ "$NFS_PORTAINER_REMOTE_PATH" != /* ]]; then
                _die "NFS remote path must begin with a slash."
            fi
            if [[ "$NFS_PORTAINER_LOCAL_PATH" == "$defaultPortainerNfslocalpath" ]]; then
                NFS_PORTAINER_LOCAL_PATH="/mnt/${NFS_PORTAINER_REMOTE_PATH##*/}"
            fi
            ;;
        -nplp=* | --nfs-portainer-local-path=*)
            NFS_PORTAINER_LOCAL_PATH="${arg#*=}"
            ;;
        -nnpmrp=* | --nfs-nginx-proxy-manager-remote-path=*)
            NFS_NGINX_PROXY_MANAGER_REMOTE_PATH="${arg#*=}"
            # Check if path begins with a slash
            if [[ "$NFS_NGINX_PROXY_MANAGER_REMOTE_PATH" != /* ]]; then
                _die "NFS remote path must begin with a slash."
            fi
            if [[ "$NFS_NGINX_PROXY_MANAGER_LOCAL_PATH" == "$defaultNginxProxyManagerNfslocalpath" ]]; then
                NFS_NGINX_PROXY_MANAGER_LOCAL_PATH="/mnt/${NFS_NGINX_PROXY_MANAGER_REMOTE_PATH##*/}"
            fi
            ;;
        -nnpmplp=* | --nfs-nginx-proxy-manager-local-path=*)
            NFS_NGINX_PROXY_MANAGER_LOCAL_PATH="${arg#*=}"
            ;;
        -na=* | --nfs-address=*)
            NFS_MOUNT_ADDRESS="${arg#*=}"
            ;;
        -pp=* | --portainer-port=*)
            PORTAINER_VIRTUAL_PORT="${arg#*=}"
            ;;
        -np=* | --nginx-proxy-managment-port=*)
            NGINX_PROXY_MANAGMENT_PORT="${arg#*=}"
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
    if [ -z "$NFS_MOUNT_ADDRESS" ]; then
        _die "NFS mount address cannot be empty. It can be an IP or FQDN."
    fi
    PORTAINER_VIRTUAL_HOST="portainer$(generateRandomString 16).$DOMAIN"
    _success "Virtual Host: $PORTAINER_VIRTUAL_HOST"
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
    # Install the NFS Utilities Package on the Server
    if [ dpkg -l | grep nfs-common ]; then
        _info "NFS Utilities Package already installed."
    else
        _info "Installing NFS Utilities Package..."
        apt install nfs-common -y && {
            _info "NFS Utilities Package installed."
        } || {
            _die "Failed to install NFS Utilities Package."
        }
    fi
    # Create NFS directories
    mkdir -p "${NFS_PORTAINER_LOCAL_PATH}"
    mkdir -p "${NFS_NGINX_PROXY_MANAGER_LOCAL_PATH}"
    # Check if NFS mount is already mounted
    if [[ -n $(mount | grep "$NFS_PORTAINER_LOCAL_PATH") ]]; then
        _info "Portainer NFS mount already mounted."
    else
        # Mount NFS
        _info "Mounting Portainer NFS share. command: \"mount ${NFS_MOUNT_ADDRESS}:${NFS_PORTAINER_REMOTE_PATH} ${NFS_PORTAINER_LOCAL_PATH}\""
        $(mount ${NFS_MOUNT_ADDRESS}:${NFS_PORTAINER_REMOTE_PATH} ${NFS_PORTAINER_LOCAL_PATH}) && {
            _success "Portainer NFS share mounted. Command \"mount ${NFS_MOUNT_ADDRESS}:${NFS_PORTAINER_REMOTE_PATH} ${NFS_PORTAINER_LOCAL_PATH}\" was successful."
        } || {
            _die "Failed to mount Portainer NFS share. Command \"mount ${NFS_MOUNT_ADDRESS}:${NFS_PORTAINER_REMOTE_PATH} ${NFS_PORTAINER_LOCAL_PATH}\" failed."
        }
    fi
    if [[ -n $(mount | grep "$NFS_NGINX_PROXY_MANAGER_LOCAL_PATH") ]]; then
        _info "Nginx Proxy Manager NFS mount already mounted."
    else
        # Mount NFS
        _info "Mounting Nginx Proxy Manager NFS share. command: \"mount ${NFS_MOUNT_ADDRESS}:${NFS_NGINX_PROXY_MANAGER_REMOTE_PATH} ${NFS_NGINX_PROXY_MANAGER_LOCAL_PATH}\""
        $(mount ${NFS_MOUNT_ADDRESS}:${NFS_NGINX_PROXY_MANAGER_REMOTE_PATH} ${NFS_NGINX_PROXY_MANAGER_LOCAL_PATH}) && {
            _success "Nginx Proxy Manager NFS share mounted. Command \"mount ${NFS_MOUNT_ADDRESS}:${NFS_NGINX_PROXY_MANAGER_REMOTE_PATH} ${NFS_NGINX_PROXY_MANAGER_LOCAL_PATH}\" was successful."
        } || {
            _die "Failed to mount Nginx Proxy Manager NFS share. Command \"mount ${NFS_MOUNT_ADDRESS}:${NFS_NGINX_PROXY_MANAGER_REMOTE_PATH} ${NFS_NGINX_PROXY_MANAGER_LOCAL_PATH}\" failed."
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
    # Install Docker Compose
    # Check if Docker Compose is already installed
    if [[ -n $(which docker-compose) ]]; then
        _info "Docker Compose is already installed."
    else
        _info "Installing Docker Compose..."
        apt-get install docker-compose -y && {
            _success "Docker Compose installed."
        } || {
            _die "Failed to install Docker Compose."
        }
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
    # Check if nginx-network already exists
    if [[ -n $(docker network ls | grep nginx-network) ]]; then
        _info "nginx-network already exists."
    else
        # Create nginx-network
        _info "Creating nginx-network..."
        docker network create nginx-network && {
            _info "nginx-network created."
        } || {
            _die "Failed to create nginx-network."
        }
    fi
    # Check if Portainer is in nginx network
    if [[ -n $(docker network inspect nginx-network | grep portainer) ]]; then
        _info "Portainer is already in nginx network."
    else
        # Add Portainer to nginx-network
        _info "Adding Portainer to nginx network..."
        docker network connect nginx-network portainer && {
            _info "Portainer added to nginx network."
        } || {
            _die "Failed to add Portainer to nginx network."
        }
    fi

    # Mount Portainer Volume
}

function deploy() {
    # Deploy Portainer
    _header "Deploying Portainer..."
    docker-compose -f "${PORTAINER_COMPOSE_FILE}" up -d && {
        _info "Portainer deployed."
    } || {
        _die "Failed to deploy Portainer."
    }
    _success "Portainer has been deployed."
    # Deploy Nginx Proxy Manager
    _header "Deploying Nginx Proxy Manager..."
    docker-compose -f "${NGINX_PROXY_MANAGER_COMPOSE_FILE}" up -d && {
        _info "Nginx Proxy Manager deployed."
    } || {
        _die "Failed to deploy Nginx Proxy Manager."
    }
}

function generatePassword() {
    echo "$(openssl rand -base64 12)"
}

function generateRandomString() {
    # Generate random string with python secrets module
    echo $(${BIN_PYTHON3} -c "import secrets; print(secrets.token_urlsafe(16))")
}

#
# MAIN
#
export LC_CTYPE=C
export LANG=C

DEBUG=0 # 1|0
_debug set -x
# Check if pyhton3 is installed
if [[ -z $(which python3) ]]; then
    # Install python3
    _info "Installing python3..."
    apt install python3 -y && {
        _info "python3 installed."
    } || {
        _die "Failed to install python3."
    }
fi
BIN_PYTHON3=$(which python3)
VERSION="0.1.0"
DOMAIN=
PORTAINER_VIRTUAL_HOST=
PORTAINER_VIRTUAL_PORT="9443"
NGINX_PROXY_MANAGMENT_PORT="81"
PORTAINER_COMPOSE_FILE="$(pwd)/cloud/portainer/docker-compose.yml"
NGINX_PROXY_MANAGER_COMPOSE_FILE="$(pwd)/cloud/portainer/nginx-proxy/docker-compose.yml"
NFS_PORTAINER_REMOTE_PATH="/portainer"
NFS_PORTAINER_LOCAL_PATH="/mnt/${NFS_PORTAINER_REMOTE_PATH#/}"
NFS_NGINX_PROXY_MANAGER_REMOTE_PATH="/nginx-proxy-manager"
NFS_NGINX_PROXY_MANAGER_LOCAL_PATH="/mnt/${NFS_NGINX_PROXY_MANAGER_REMOTE_PATH#/}"
NFS_MOUNT_ADDRESS=

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
    # Parse variables to environment for docker-compose
    export DOMAIN
    export PORTAINER_VIRTUAL_HOST
    export PORTAINER_VIRTUAL_PORT
    export NGINX_PROXY_MANAGMENT_PORT
    export NFS_PORTAINER_REMOTE_PATH
    export NFS_PORTAINER_LOCAL_PATH
    export NFS_MOUNT_ADDRESS
    # Create directories
    mkdir -p "${NFS_NGINX_PROXY_MANAGER_LOCAL_PATH}/data"
    mkdir -p "${NFS_NGINX_PROXY_MANAGER_LOCAL_PATH}/letsencrypt"
    # Install Portainer
    installPortainer
    # Deploy Portainer
    deploy
}

main "$@"

_debug set +x
