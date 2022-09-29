#!/bin/bash

source "../../core/lib.sh"

#
# FUNCTIONS
#

function _usage() {
    echo -n "$(basename $0) [OPTION]...

Script to create a virtual machine with cli providers (default: oci)
Version $VERSION

    Options:
        -n, --name                  Virtual machine name
        -p, --provider              Virtual machine provider (oci|aws|gcp) # TODO: add support for other providers
        -i, --image                 Virtual machine image (default: Oracle-Linux-7.9-2021.01.12-0)
        -s, --size                  Virtual machine size (default: VM.Standard.A1.Flex)
        -r, --region                Virtual machine region (default: sa-santiago-1)
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

}

function generatePassword() {
    echo "$(openssl rand -base64 12)"
}

#
# MAIN
#
export LC_CTYPE=C
export LANG=C

DEBUG=0 # 1|0
_debug set -x
VERSION="0.1.0"
DEFAULT_CLI_PROVIDER="oci"

function main() {

}

main "$@"

_debug set +x
