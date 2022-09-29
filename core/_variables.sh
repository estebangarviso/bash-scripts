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

_white=$(tput setaf 7)
_purple=$(tput setaf 171)
_red=$(tput setaf 1)
_green=$(tput setaf 76)
_tan=$(tput setaf 3)
_blue=$(tput setaf 38)
_yellow=$(tput setaf 11)
_light_yellow=$(tput setaf 11)

_errors=
_successes=
_warnings=

_log_file="$(pwd)/logs/$(echo $0 | sed 's/\.\///g' | sed 's/\.sh//g' | sed 's/\//_/g')_$(date +%Y-%m-%d_%H:%M:%S).log"

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
    # Log to file
    echo "==========  $@  ==========" >>"$_log_file"
}

function _arrow() {
    printf "➜ $@\n"
    # Log to file
    echo "➜ $@" >>"$_log_file"
}

function _info() {
    printf "${_bold}${_blue}ⓘ︎ $@${_reset}\n"
    # Log to file
    echo "INFO: $@" >>"$_log_file"
}

function _success() {
    printf "${_green}✔ %s${_reset}\n" "$@"
    _addMessage "$@" "success"
    # Log to file
    echo "SUCCESS: $@" >>"$_log_file"
}

function _error() {
    printf "${_red}✖ %s${_reset}\n" "$@"
    _addMessage "$@" "error"
    # Log to file
    echo "ERROR: $@" >>"$_log_file"
}

function _warning() {
    printf "${_tan}⚠ %s${_reset}\n" "$@"
    _addMessage "$@" "warning"
    # Log to file
    echo "WARNING: $@" >>"$_log_file"
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
    _error "Critical error: $@"
    _addMessage "Critical error: $@" "error"
    exit 1
}

function _safeExit() {
    exit 0
}
