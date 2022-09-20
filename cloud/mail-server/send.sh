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

Script to send an email from a mail server with SSL/TLS enabled.
Version $VERSION

    Options:
        -d, --domain                Domain name
        -f, --from                  Sender email address
        -t, --to                    Recipient email address
        -s, --subject               Subject
        -b, --body                  Body

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
        -d=* | --domain=*)
            DOMAIN="${arg#*=}"
            ;;
        -f=* | --from=*)
            FROM="${arg#*=}"
            ;;
        -t=* | --to=*)
            TO="${arg#*=}"
            ;;
        -s=* | --subject=*)
            SUBJECT="${arg#*=}"
            ;;
        -b=* | --body=*)
            BODY="${arg#*=}"
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
    [[ -z "$DOMAIN" ]] && DOMAIN="$(hostname -d)"
    [[ -z "$FROM" ]] && FROM="admin@$DOMAIN"
    [[ -z "$TO" ]] && _die "Recipient email address is required."
    [[ -z "$SUBJECT" ]] && SUBJECT=""
    [[ -z "$BODY" ]] && _die "Body is required"
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
FROM=
TO=
SUBJECT=
BODY=

function main() {
    processArgs "$@"
    _header "Sending email from $FROM to $TO"
    echo "$BODY" | mail -s "$SUBJECT" -r "$FROM" "$TO"
}

main "$@"
_debug set +x
