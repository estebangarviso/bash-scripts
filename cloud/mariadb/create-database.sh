#!/bin/bash

# source "../../core/lib.sh"
wget -qO- https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/core/lib.sh | bash

#
# FUNCTIONS
#

function _usage() {
    echo -n "$(basename $0) [OPTION]...

Create MySQL db & user.
Version $VERSION

    Options:
        -ht, --host         MySQL Host (default: localhost)
        -db, --database     MySQL Database name (mandatory)
        -r, --random        Append random number to database name (optional)
        -u, --user          MySQL User (default: database name)
        -p, --pass          MySQL Password (If empty, auto-generated)
        -h, --help          Display this help and exit
        -v, --version       Output version information and exit

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
        -ht=* | --host=*)
            DB_HOST="${arg#*=}"
            ;;
        -db=* | --database=*)
            DB_NAME="${arg#*=}"
            ;;
        -r=* | --random=*)
            [[-z $DB_NAME ]] && _die "Database name is mandatory"
            DB_NAME="${DB_NAME}$(_generateRandomNumbers 3)"
            ;;
        -u=* | --user=*)
            DB_USER="${arg#*=}"
            ;;
        -p=* | --pass=*)
            DB_PASS="${arg#*=}"
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
    [[ -z $DB_NAME ]] && _die "Database name cannot be empty."
    [[ $DB_USER ]] || DB_USER=$DB_NAME
}

function generatePassword() {
    echo "$(openssl rand -base64 12)"
}

function getFirstChars() {
    local word=$1
    local length=$2
    echo ${word:0:$length}
}

function createMysqlDbUser() {
    SQL1="CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
    SQL2="CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';"
    SQL3="GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';"
    SQL4="FLUSH PRIVILEGES;"

    if [ -f /root/.my.cnf ]; then
        $BIN_MYSQL -e "${SQL1}${SQL2}${SQL3}${SQL4}"
    elif [ -n "$MYSQL_ROOT_PASSWORD" ]; then
        $BIN_MYSQL -h $DB_HOST -u root -p${MYSQL_ROOT_PASSWORD} -e "${SQL1}${SQL2}${SQL3}${SQL4}"
    else
        # If /root/.my.cnf doesn't exist then it'll ask for root password
        _arrow "Please enter root user MySQL password!"
        # Read and hide password
        read -s -p "Password: " MYSQL_ROOT_PASSWORD
        $BIN_MYSQL -h $DB_HOST -u root -p${MYSQL_ROOT_PASSWORD} -e "${SQL1}${SQL2}${SQL3}${SQL4}"
    fi
}

function printSuccessMessage() {
    _success "MySQL DB / User creation completed!"

    echo "################################################################"
    echo ""
    echo " >> Host          : ${DB_HOST}"
    echo " >> Database name : ${DB_NAME}"
    echo " >> User name     : ${DB_USER}"
    echo " >> Password      : ${DB_PASS}"
    echo ""
    echo "################################################################"
    _printPoweredBy
}

#
# MAIN
#
export LC_CTYPE=C
export LANG=C

DEBUG=0 # 1|0
_debug set -x
VERSION="0.1.0"

BIN_MYSQL=$(which mysql)

export DB_HOST='localhost'
export DB_NAME=
export DB_USER=
export DB_PASS=$(generatePassword)

function main() {
    [[ $# -lt 1 ]] && _usage
    _success "Processing arguments..."
    processArgs "$@"
    _success "Done!"

    _success "Creating MySQL db and user..."
    createMysqlDbUser
    _success "Done!"

    printSuccessMessage
}

main "$@"

_debug set +x
