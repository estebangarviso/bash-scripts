#!/bin/bash

source "$(pwd)/core/lib.sh"

# Sanity check
_checkSanity

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
    if [ -z "$DOMAIN" ]; then
        _die "Domain name cannot be empty."
    fi
    if [ -z "$FROM" ]; then
        _die "Sender email address cannot be empty."
    fi
    if [ -z "$TO" ]; then
        _die "Recipient email address cannot be empty."
    fi
    if [ -z "$SUBJECT" ]; then
        _die "Subject cannot be empty."
    fi
    if [ -z "$BODY" ]; then
        _die "Body cannot be empty."
    fi
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
