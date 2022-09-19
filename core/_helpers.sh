#!/bin/bash
lib_name='functions'
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
    local length=$1
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

function _checkRoot() {
    if [ "$(whoami)" != 'root' ] || [[ $EUID -ne 0 ]]; then
        echo "You have no permission to run $0 as non-root user. Use sudo"
        exit 1
    fi
}

function _sendEmail() {
    local to=$1
    local subject=$2
    local body=$3
    local from=$4
    if [ -z "$from" ]; then
        from="no-reply@$(hostname)"
    fi
    echo "$body" | mail -s "$subject" -r "$from" "$to"
}

function _getPublicIP() {
    local ip=$(curl -s http://checkip.amazonaws.com)
    echo $ip
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
