#!/bin/bash
lib_name_helpers='helpers'
lib_version_helpers=20221309

#
# TO BE SOURCED ONLY ONCE:
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

if [[ " ${g_libs[*]} " =~ " ${lib_name_helpers}@${lib_version_helpers} " ]]; then
    return 0
else
    g_libs+=("$lib_name_helpers@$lib_version_helpers")
fi

# Check if _variables.sh is already in the array g_libs if not show error and exit
if [[ " ${g_libs[*]} " =~ " ${lib_name_variables}@${lib_version_variables} " ]]; then
    :
else
    echo "ERROR: ${lib_name_variables} is not loaded"
    exit 1
fi

#
# UTILITY HELPER
#
function _sed() {
    local search=$1
    local replace="$(echo "$2" | sed 's/\//\\\//g')"
    local file=$3
    if [[ $(uname -s | grep -i darwin) ]]; then
        sed -i '' "s/$search/$replace/g" $file && {
            return 0
        } || {
            return 1
        }
    else
        sed -i "s/$search/$replace/g" $file && {
            return 0
        } || {
            return 1
        }
    fi
}

function _generateRandomNumbers() {
    local length=${1:-12}
    echo $(cat /dev/urandom | tr -dc '0-9' | fold -w $length | head -n 1)
}

function _seekConfirmation() {
    printf "\n${_bold}$@${_reset}"
    read -p " (Y/n) " -n 1
    printf "\n"
}

# Test whether the result of an 'ask' is a confirmation
function _isConfirmed() {
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}

function _typeExists() {
    if [ $(type -P $1) ]; then
        return 0
    fi
    return 1
}

function _checkSanity() {
    if [ "$(whoami)" != 'root' ] || [[ $EUID -ne 0 ]]; then
        printf "You have no permission to run $0 as non-root user. Use sudo\n"
        exit 1
    fi
    # Check if the script is being run on a supported OS
    if [[ ! $(uname -s | grep -i darwin) ]] && [[ ! $(uname -s | grep -i linux) ]]; then
        printf "This script only supports Linux and macOS\n"
        exit 1
    fi
    local binBash=$(which bash)
    # Check if brew is installed on macOS, if not, install it
    if [[ $(uname -s | grep -i darwin) ]] && [[ ! $(which brew) ]]; then
        printf "Installing brew...\n"
        binBash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        printf "Brew installed\n"
    fi
}

function _sendEmail() {
    local to=
    local subject=
    local body=
    local from=
    for i in "$@"; do
        case $i in
        -t=* | --to=*)
            to="${i#*=}"
            shift
            ;;
        -s=* | --subject=*)
            subject="${i#*=}"
            shift
            ;;
        -b=* | --body=*)
            body="${i#*=}"
            shift
            ;;
        esac
    done

    if [[ -z "$to" ]] || [[ -z "$subject" ]] || [[ -z "$body" ]]; then
        printf "You must specify all the required parameters which are:\n"
        printf " -t, --to: the recipient of the email\n"
        printf " -s, --subject: the subject of the email\n"
        printf " -b, --body: the body of the email\n"
        return 1
    fi
    mail -s "$subject" "$to" <<<"$body" && {
        _success "Email sent successfully"
        return 0
    } || {
        _error "Failed to send email"
        return 1
    }
}

function _addError() {
    if [[ -z "$1" ]]; then
        return 1
    fi
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    if [ -z "$_errors" ]; then
        _errors="[ERROR] $timestamp: $1"
    else
        _errors="$_errors\n[ERROR] $timestamp: $1"
    fi
}

function _addWarning() {
    if [[ -z "$1" ]]; then
        return 1
    fi
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    if [ -z "$_warnings" ]; then
        _warnings="[WARNING] $timestamp: $1"
    else
        _warnings="$_warnings\n[WARNING] $timestamp: $1"
    fi
}

function _addSuccess() {
    if [[ -z "$1" ]]; then
        return 1
    fi
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    if [ -z "$_successes" ]; then
        _successes="[SUCCESS] $timestamp: $1"
    else
        _successes="$_successes\n[SUCCESS] $timestamp: $1"
    fi
}

function _addMessage() {
    local message=$1
    local type
    if [[ -z "$message" ]]; then
        return 1
    fi
    [[ -z "$2" ]] && type="" || type="$2"
    case $type in
    "error")
        _addError "$message"
        ;;
    "warning")
        _addWarning "$message"
        ;;
    "success")
        _addSuccess "$message"
        ;;
    esac
}

function _startService() {
    local service=$1
    if [[ -z "$service" ]]; then
        return 1
    fi
    local status
    local message
    case "$OSTYPE" in
    linux*)
        if pidof systemd; then
            {
                systemctl start $service
                status=$?
                message="Starting $service"
            } || {
                status=$?
                message="Failed to start $service"
            }
        else
            {
                service $service start
                status=$?
                message="Starting $service"
            } || {
                status=$?
                message="Failed to start $service"
            }
        fi
        ;;
    darwin*)
        {
            brew services start $service
            status=$?
            message="Starting $service"
        } || {
            status=$?
            message="Failed to start $service"
        }
        ;;
    esac
    if [[ $status -eq 0 ]]; then
        _success "$message"
    else
        _error "$message"
    fi
    return $status
}

function _stopService() {
    local service=$1
    if [[ -z "$service" ]]; then
        return 1
    fi
    local status
    local message
    case "$OSTYPE" in
    linux*)
        if pidof systemd; then
            {
                systemctl stop $service
                status=$?
                message="Stopping $service"
            } || {
                status=$?
                message="Failed to stop $service"
            }
        else
            {
                service $service stop
                status=$?
                message="Stopping $service"
            } || {
                status=$?
                message="Failed to stop $service"
            }
        fi
        ;;
    darwin*)
        {
            brew services stop $service
            status=$?
            message="Stopping $service"
        } || {
            status=$?
            message="Failed to stop $service"
        }
        ;;
    esac
    if [[ $status -eq 0 ]]; then
        _success "$message"
    else
        _error "$message"
    fi
    return $status
}

function _restartService() {
    local service=$1
    if [[ -z "$service" ]]; then
        return 1
    fi
    local status
    local message
    case "$OSTYPE" in
    linux*)
        if pidof systemd; then
            {
                systemctl restart $service
                status=$?
                message="Restarting $service"
            } || {
                status=$?
                message="Failed to restart $service"
            }
        else
            {
                service $service restart
                status=$?
                message="Restarting $service"
            } || {
                status=$?
                message="Failed to restart $service"
            }
        fi
        ;;
    darwin*)
        {
            brew services restart $service
            status=$?
            message="Restarting $service"
        } || {
            status=$?
            message="Failed to restart $service"
        }
        ;;
    esac
    if [[ $status -eq 0 ]]; then
        _success "$message"
    else
        _error "$message"
    fi
    return $status
}

function _getPublicIP() {
    local ip=$(curl -s http://checkip.amazonaws.com)
    echo $ip
}

function _checkUrl() {
    local link=
    for i in "$@"; do
        case $i in
        -l=* | --link=*)
            link="${i#*=}"
            shift
            ;;
        *)
            printf "Unknown option: $i\n"
            ;;
        esac
    done
    if [[ -z "$link" ]]; then
        printf "You must specify all the required parameters which are:\n"
        printf " -l, --link: the link to check\n"
        return 1
    fi

    if which wget >/dev/null; then
        wget -q --spider $link
        if [ $? -eq 0 ]; then
            return 0
        else
            return 1
        fi
    elif which curl >/dev/null; then
        curl -s --head $link | head -n 1 | grep "200 OK" >/dev/null
        if [ $? -eq 0 ]; then
            return 0
        else
            return 1
        fi
    else
        case $OSTYPE in
        linux*)
            apt-get -qq -y install wget
            ;;
        darwin*)
            brew install wget
            ;;
        esac

        if which wget >/dev/null; then
            wget -q --spider $link
            if [ $? -eq 0 ]; then
                return 0
            else
                return 1
            fi
        else
            return 1
        fi
    fi
    return 1
}

function _upperCase() {
    echo "$@" | tr '[:lower:]' '[:upper:]'
}

function _capitalize() {
    echo "$@" | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1'
}

function _validateEmail() {
    local email=$@
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]]; then
        return 0
    fi
    return 1
}

function _validateDomain() {
    local domain=$@
    if [[ $domain =~ ^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$ ]]; then
        return 0
    fi
    return 1
}

function _validateHostname() {
    local hostname=$@
    if [[ $hostname =~ ^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$ ]]; then
        return 0
    fi
    return 1
}

function _compareVersion() {
    local version1=$1
    local version2=$2
    if [[ -z "$version1" || -z "$version2" ]]; then
        echo "You must specify two versions to compare"
        return
    fi
    if [[ $version1 == $version2 ]]; then
        return 'equal'
    fi
    local IFS=.
    local i ver1=($version1) ver2=($version2)
    # fill empty fields in ver1 with zeros
    for ((i = ${#ver1[@]}; i < ${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i = 0; i < ${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 'greater'
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 'less'
        fi
    done
    return 'unknown'
}

function _isInstalled() {
    local package=$1
    if [[ -z "$package" ]]; then
        return 1
    fi
    if which $package >/dev/null; then
        return 0
    fi
    return 1
}

function _printPoweredBy() {
    cat <<EOF

$_bold$_green
Powered by:                                                                                       
$_bold$_reset$_blue
          'ccll;                         
      .clod0NNNX.                        
     .'OOxddKNNN0.                 ..... 
 ,coddXXXXKdxXXXXNNNNNXKOd:. .';coKNNXXc 
 ;OOxdxXNNNKKKXNNWNNNNNNNNNNK0xdkXNNN0.  
  cOOxdkNNNNKxONNNNXKNNNNNNNXxdKNNNNd    
   dkKxdONNNNkd0NNNX' .,oKX0dkNNNNX;     
  'xNWXxdKNNNXkdXNNN0. .okxdKWNNNWWl     
 ,kNWWW0xdXNNNXkxNNNNk,kkdkNWWWWWWWWl    
.dXWNNNNOdxNNNNKkkNWWWKxxKWWWWNWWWWWW.   
;ONNNNNNOkdkNNNN0k0WWWW0OXWWWdoXWWWWWo   
l0NNNNNXOOxd0NNNN0kKWWWW00NX, :KWWWWWx   
c0NNNNN0kOkxdXNNNN0OXNNXOl;.  cKNNWWWd   
.kXNNNNNlOOkxxNWWWXc:,.      .xNNNNNN,   
 l0NNNNNXdOOkxkNWWWl        .oXNNNNNx    
  oKNNNNNNX0OkdOWWWW;      ;OXNNNNNk.    
   c0NNNNNNNXKkdKWWWN.  'o0NNNNNNXo      
    .oKNNNNWWWXxdXWWWXKNWWWWNNNNk.       
      .cOXWWWWWKxxNWWWWWWWWWWKo.         
         .;oOXWW0xkWWWWWN0x:.            
              l00kx0WWWW;                
               xOOkkKKOd;                
               .;;;;,.                   
$_reset

 >> Website: https://virtualsense.cl

################################################################
EOF
}

# Parse helper arguments
for arg in "$@"; do
    case $arg in
    NOTIFY_TO=*)
        _SCRIPT_EMAIL_NOTIFIER="${arg#*=}"
        _info "This script will send notifications to $_SCRIPT_EMAIL_NOTIFIER"
        shift
        ;;

    esac
done
