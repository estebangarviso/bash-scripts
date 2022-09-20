#!/bin/bash

source "$(pwd)/core/lib.sh"

# References:
# - Oracle Cloud Infrastructure (OCI) CLI: https://docs.oracle.com/en/solutions/move-data-to-cloud-storage-using-rclone/index.html#GUID-13EF8474-9517-4043-9638-8EE04FE6C565

#
# FUNCTIONS
#

function _usage() {
    echo -n "$(basename $0) [OPTION]...

Script to install rclone.
Version $VERSION

    Options:
        -n, --name                  Rclone name (default: oci)
        -d, --drive                 Rclone drive type (default: s3)
        -r, --region                Rclone region (default: sa-santiago-1)
        -e, --endpoint              Rclone endpoint (mandatory. Example for oci: https://your_object_storage_namespace.compat.objectstorage.<region>.oraclecloud.com)
        -a, --access-key            Rclone access key (mandatory)
        -s, --secret-key            Rclone secret key (mandatory)
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
        -p=* | --provider=*)
            RCLONE_CONFIG_NAME="${arg#*=}"
            ;;
        -t=* | --type=*)
            RCLONE_CONFIG_DRIVE="${arg#*=}"
            ;;
        -r=* | --region=*)
            RCLONE_CONFIG_REGION="${arg#*=}"
            ;;
        -e=* | --endpoint=*)
            RCLONE_CONFIG_ENDPOINT="${arg#*=}"
            ;;
        -a=* | --access-key=*)
            RCLONE_CONFIG_ACCESS_KEY="${arg#*=}"
            ;;
        -s=* | --secret-key=*)
            RCLONE_CONFIG_SECRET_KEY="${arg#*=}"
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
    [[ -z $RCLONE_CONFIG_ENDPOINT ]] && _die "Endpoint is mandatory"
    [[ -z $RCLONE_CONFIG_ACCESS_KEY ]] && _die "Access key is mandatory"
    [[ -z $RCLONE_CONFIG_SECRET_KEY ]] && _die "Secret key is mandatory"
}

function generatePassword() {
    echo "$(openssl rand -base64 12)"
}

function install() {
    _header "Installing rclone"
    curl https://rclone.org/install.sh | bash
    _success "rclone installed!"
}

function configure() {
    _header "Configuring rclone"
    mkdir -p ~/.config/rclone #https://forum.rclone.org/t/how-can-i-auto-configure-most-of-rclone-config/3628
    _success "rclone configured!"
}

#
# MAIN
#
export LC_CTYPE=C
export LANG=C

DEBUG=0 # 1|0
_debug set -x
VERSION="0.1.0"

export RCLONE_CONFIG_NAME="oci"
export RCLONE_CONFIG_DRIVE="s3"
export RCLONE_CONFIG_ACCESS_KEY_ID=
export RCLONE_CONFIG_SECRET_ACCESS_KEY=
export RCLONE_CONFIG_REGION='sa-santiago-1'
export RCLONE_CONFIG_ENDPOINT=

function main() {
    [[ $# -lt 1 ]] && _usage
    # Process arguments
    processArgs "$@"
    # Install rclone
    install

}

main "$@"

_debug set +x
