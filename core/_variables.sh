#!/bin/sh
lib_name='variables'
lib_version=20221309

#
# TO BE SOURCED ONLY ONCE:
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

if test "${g_libs[$lib_name]+_}"; then
    return 0
else
    if test ${#g_libs[@]} == 0; then
        declare -A g_libs
    fi
    g_libs[$lib_name]=$lib_version
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

#
# HEADERS & LOGGING
#
function _debug() {
    [ "$DEBUG" -eq 1 ] && $@
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
    exit 1
}

function _safeExit() {
    exit 0
}

function _addMessage() {
    local message=$1
    local type
    [[ -z "$2" ]] && type="" || type="$2"
    case $type in
    error)
        [[ -z "$_errorMsgs" ]] && _errorMsgs="$message" || _errorMsgs="$_errorMsgs\n$message"
        ;;
    success)
        [[ -z "$_successMsgs" ]] && _successMsgs="$message" || _successMsgs="$_successMsgs\n$message"
        ;;
    *)
        echo "$message"
        ;;
    esac
}

function _getMessages() {
    local type
    local html
    html="<h1>Report</h1>"
    [[ -z "$1" ]] && type="" || type="$1"
    case $type in
    error)
        echo "$_errorMsgs"
        ;;
    success)
        echo "$_successMsgs"
        ;;
    htmlReport)
        [[ -z "$_errorMsgs" ]] || html="$html <h2>Errors</h2> <pre>$_errorMsgs</pre>"
        [[ -z "$_successMsgs" ]] || html="$html <h2>Successes</h2> <pre>$_successMsgs</pre>"
        ;;

    esac
}
