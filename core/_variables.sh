#!/bin/bash
lib_name_variables='variables'
lib_version_variables=20221309

#
# TO BE SOURCED ONLY ONCE:
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# check if lib is already in the array g_libs
if [[ " ${g_libs[*]} " =~ " ${lib_name_variables}@${lib_version_variables} " ]]; then
    return 0
else
    g_libs+=("$lib_name_variables@$lib_version_variables")
fi

#
# VARIABLES
#
_bold=$(tput bold)
_underline=$(tput sgr 0 1)
_reset=$(tput sgr0)

_purple=$(tput setaf 171)
_red=$(tput setaf 1)
_green=$(tput setaf 76)
_tan=$(tput setaf 3)
_blue=$(tput setaf 38)

_errorMsgs=
_successMsgs=

_logFile=".bash-scripts.log"
LOGS_DIR="$HOME/.bash-scripts/logs"

DEBUG=0

#
# HEADERS & LOGGING
#
function _debug() {
    if [ "$DEBUG" -eq 1 ]; then
        $@
    fi
}

function _header() {
    printf "\n${_bold}${_purple}==========  %s  ==========${_reset}\n" "$@"
}

function _arrow() {
    printf "➜ $@\n"
}

function _success() {
    printf "${_green}✔ %s${_reset}\n" "$@"
}

function _error() {
    printf "${_red}✖ %s${_reset}\n" "$@"
}

function _warning() {
    printf "${_tan}➜ %s${_reset}\n" "$@"
}

function _underline() {
    printf "${_underline}${_bold}%s${_reset}\n" "$@"
}

function _bold() {
    printf "${_bold}%s${_reset}\n" "$@"
}

function _note() {
    printf "${_underline}${_bold}${_blue}Note:${_reset}  ${_blue}%s${_reset}\n" "$@"
}

function _die() {
    _error "$@"
    _addMessage "$@" "error"
    _logMessages
    exit 1
}

function _safeExit() {
    exit 0
}

function _addMessage() {
    local message=$1
    local type
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    [[ -z "$2" ]] && type="" || type="$2"
    case $type in
    error)
        if [ -z "$_errorMsgs" ]; then
            _errorMsgs="$timestamp: $message"
        else
            _errorMsgs="$_errorMsgs\n$timestamp: $message"
        fi
        ;;
    success)
        if [ -z "$_successMsgs" ]; then
            _successMsgs="$timestamp: $message"
        else
            _successMsgs="$_successMsgs\n$timestamp: $message"
        fi
        ;;
    *)
        echo "$message"
        ;;
    esac
}

function _getMessages() {
    local type
    local html
    local log
    html="<h1>Report</h1>"
    [[ -z "$1" ]] && type="" || type="$1"
    [[ -z "$2" ]] && log="" || log="$2"
    case $type in
    error)
        echo "$_errorMsgs"
        ;;
    success)
        echo "$_successMsgs"
        ;;
    htmlReport)
        [[ -z "$_errorMsgs" ]] || html+="<h2>Errors</h2> <pre>$_errorMsgs</pre>"
        [[ -z "$_successMsgs" ]] || html+="<h2>Successes</h2> <pre>$_successMsgs</pre>"
        echo "$html"
        ;;
    esac
}

function _logMessages() {
    [[ -z LOGS_DIR ]] && LOGS_DIR="~/logs"
    [[ -d $LOGS_DIR ]] || mkdir -p $LOGS_DIR
    # Add time stamp
    local timestamp=$(date +%Y%m%d%H%M%S)
    touch $LOGS_DIR/$_logFile
    cat <<EOF >>$LOGS_DIR/$_logFile
----------------------------------------
Script: $0
Timestamp: $timestamp
----------------------------------------
Error messages:
$_errorMsgs
Success messages:
$_successMsgs
----------------------------------------
EOF
}
