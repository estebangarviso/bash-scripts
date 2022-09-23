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

#
# UTILITY HELPER
#
function _sed() {
    local search=$1
    local replace=$2
    local file=$3
    if [[ $(uname -s | grep -i darwin) ]]; then
        sed -i '' "s/$search/$replace/g" $file
    else
        sed -i "s/$search/$replace/g" $file
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
        -f=* | --from=*)
            from="${i#*=}"
            shift
            ;;
        *)
            printf "Unknown option: $i"
            ;;
        esac
    done
    if [ -z "$from" ]; then
        from="no-reply@$(hostname)"
    fi
    if [[ -z "$to" ]] || [[ -z "$subject" ]] || [[ -z "$body" ]]; then
        printf "You must specify all the required parameters which are:\n"
        printf " -t, --to: the recipient of the email\n"
        printf " -s, --subject: the subject of the email\n"
        printf " -b, --body: the body of the email\n"
        return 1
    fi
    echo "$body" | mail -s "$subject" -r "$from" "$to"
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
