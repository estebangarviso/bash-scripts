# Contribution: Luca Borrione
# Reference: https://stackoverflow.com/questions/64786/error-handling-in-bash#answer-13099228
lib_name_trap='trap'
lib_version_trap=20121026

stderr_log="$(pwd)/tmp/stderr"
if [ ! -f "$stderr_log" ]; then
    touch "$stderr_log"
fi

#
# TO BE SOURCED ONLY ONCE:
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

if [[ " ${g_libs[*]} " =~ " ${lib_name_trap}@${lib_version_trap} " ]]; then
    return 0
else
    g_libs+=("$lib_name_trap@$lib_version_trap")
fi

# check if _variables.sh and _helpers.sh are already in the array g_libs if not show error and exit
if [[ " ${g_libs[*]} " =~ " ${lib_name_variables}@${lib_version_variables} " ]]; then
    :
else
    echo "ERROR: ${lib_name_variables} is not loaded"
    exit 1
fi

if [[ " ${g_libs[*]} " =~ " ${lib_name_helpers}@${lib_version_helpers} " ]]; then
    :
else
    echo "ERROR: ${lib_name_helpers} is not loaded"
    exit 1
fi

#
# MAIN CODE:
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

set -o pipefail # trace ERR through pipes
set -o errtrace # trace ERR through 'time command' and other functions
set -o nounset  ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit  ## set -e : exit the script if any statement returns a non-true return value

exec 2>"$stderr_log"

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#
# FUNCTION: EXCEPTION_HANDLER
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

function sendReport() {
    # Copy _email.template.html to email.html
    local email_subject="Script $0 execution report from $(hostname)"
    if [[ ! -z $_SCRIPT_EMAIL_NOTIFIER ]]; then
        _sendEmail --subject="${email_subject}" --to="$_SCRIPT_EMAIL_NOTIFIER" --body="$(cat "$_log_file")"
    fi
}

function exception_handler() {
    _SCRIPT_EMAIL_NOTIFIER=${_SCRIPT_EMAIL_NOTIFIER:-}
    set -u # unset variables are errors
    local exit_code=$1
    # Check if exit code and stderr_log is empty
    if [[ -z $exit_code ]] || ([[ ! -s $stderr_log ]] && [[ $exit_code -eq 0 ]]); then
        sendReport
        return 0
    fi
    #
    # LOCAL VARIABLES:
    # ------------------------------------------------------------------
    #
    local i=0
    local regex=''
    local mem=''

    local error_file=''
    local error_lineno=''
    local error_message=''

    local lineno=''

    #
    # PRINT THE HEADER:
    # ------------------------------------------------------------------
    #
    # Color the output if it's an interactive terminal
    # _error "ERROR: An error was encountered with the script."

    if [ -t 1 ]; then
        printf "${_red}${_bold}"
    fi

    #
    # GETTING LAST ERROR OCCURRED:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

    #
    # Read last file from the error log
    # ------------------------------------------------------------------
    #
    local stderr=
    if test -f "$stderr_log"; then
        stderr=$(tail -n 1 "$stderr_log")
        # rm -f "$stderr_log"
    fi

    #
    # Managing the line to extract information:
    # ------------------------------------------------------------------
    #

    if test -n "$stderr"; then
        # Split stderr on ": "
        mem="$IFS"
        local shrunk_stderr=$(echo "$stderr" | sed -e 's/: /:/g')
        IFS=':'
        local stderr_parts=($shrunk_stderr)
        IFS="$mem"

        # Storing information on the error
        error_file="${stderr_parts[0]}"
        error_lineno="${stderr_parts[1]}"
        error_message=""

        for ((i = 3; i <= ${#stderr_parts[@]}; i++)); do
            error_message="$error_message "${stderr_parts[$i - 1]}": "
        done

        # Removing last ':' (colon character)
        error_message="${error_message%:*}"

        # Trim
        error_message="$(echo "$error_message" | sed -e 's/^[ \t]*//' | sed -e 's/[ \t]*$//')"
    fi

    if [ -z "$error_file" ]; then
        error_file=$(basename "$0")
    fi

    #
    # GETTING BACKTRACE:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
    _backtrace=$(backtrace 2)

    #
    # MANAGING THE OUTPUT:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

    local lineno=""
    # Regex to match the line number. e.g. "line 123"
    regex='^([a-z]{1,}) ([0-9]{1,})$'

    if [[ $error_lineno =~ $regex ]]; then # The error line was found on the log
        # (e.g. type 'ff' without quotes wherever)
        # --------------------------------------------------------------
        local row="${BASH_REMATCH[1]}"
        lineno="${BASH_REMATCH[2]}"

        if [ -t 1 ]; then
            printf "${_light_yellow}"
        fi
        printf "${error_message} in ${error_file} line ${lineno}\n"
        _addMessage "${error_message} in ${error_file} line ${lineno}" "error"
    else
        regex="^${error_file}\$|^${error_file}\s+|\s+${error_file}\s+|\s+${error_file}\$"
        if [[ $_backtrace =~ $regex ]]; then

            # (could not reproduce this case so far)
            # ------------------------------------------------------

            if [ -t 1 ]; then
                printf "${_light_yellow}"
            fi
            printf "${stderr} in $error_file line unknown\n"
            _addMessage "${error_message} in ${error_file} line unknown" "error"

        # Neither the error line nor the error file was found on the log
        # (e.g. type 'cp ffd fdf' without quotes wherever)
        # ------------------------------------------------------
        else
            #
            # The error file is the first on backtrace list:

            # Split backtrace on newlines
            mem=$IFS
            IFS='
            '
            #
            # Substring: I keep only the carriage return
            # (others needed only for tabbing purpose)
            IFS=${IFS:0:1}
            local lines=($_backtrace)

            IFS=$mem

            error_file=""
            if test -n "${lines[1]}"; then
                array=(${lines[1]})

                for ((i = 2; i < ${#array[@]}; i++)); do
                    error_file="$error_file ${array[$i]}"
                done

                # Trim
                error_file="$(echo "$error_file" | sed -e 's/^[ \t]*//' | sed -e 's/[ \t]*$//')"
            fi

            if [ -t 1 ]; then
                printf "${_light_yellow}"
            fi
            local blockErrorMessage=
            if test -n "${stderr}"; then
                printf "${stderr}"
                blockErrorMessage="${stderr}"
            else
                printf "${error_message}"
                blockErrorMessage="${error_message}"
            fi
            printf " in $error_file line unknown\n"
            _addMessage "${blockErrorMessage} in ${error_file} line ${lineno}" "error"
        fi
    fi

    #
    # PRINTING THE BACKTRACE:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

    if [ -t 1 ]; then
        printf "${_white}${_bold}"
    fi
    printf "\n$_backtrace\n"
    _addMessage "$_backtrace" "error"

    #
    # EXITING:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

    if [ -t 1 ]; then
        printf "${_red}${_bold}"
    fi

    if [ -t 1 ]; then
        printf "${_reset}"
    fi

    if [[ ! -z $_SCRIPT_EMAIL_NOTIFIER ]]; then
        # Send email
        sendReport
    fi
    exit "$exit_code"
}
trap 'rc=$?; exception_handler $rc; exit $rc' ERR EXIT

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#
# FUNCTION: BACKTRACE
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

function backtrace {
    local _start_from_=0

    local params=("$@")
    if (("${#params[@]}" >= "1")); then
        _start_from_="$1"
    fi

    local i=0
    local first=false
    while caller $i >/dev/null; do
        if test -n "$_start_from_" && (("$i" + 1 >= "$_start_from_")); then
            if test "$first" == false; then
                printf "\nBacktrace:\n"
                first=true
            fi
            caller $i
        fi
        let "i=i+1"
    done
}

return 0
