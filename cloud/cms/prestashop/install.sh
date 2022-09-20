#!/bin/bash

source "$(pwd)/core/lib.sh"

#
# FUNCTIONS
#

function _usage() {
    echo -n "$(basename $0) [OPTION]...

Automatically create a CMS Prestashop.
Version $VERSION

    Options:
        -w, --website               Install from website
        -dp, --dirpath              Directory path (it will be created if not exists)
        -dbn, --database-name       Database name
        -dbu, --database-user       Database user
        -dbp, --database-pass       Database password
        -dbht, --database-host      Database host (default: localhost)
        -dbpt, --database-port      Database port (default: 3306)
        -h, --help                  Display this help and exit
        -v, --version               Output version information and exit

    Examples:
        $(basename $0) --

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

function main() {

}

main "$@"

_debug set +x
