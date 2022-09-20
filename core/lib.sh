[[ -z $CORE_SOURCE ]] && {
    _coreDir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    # Install curl if not installed
    [[ -z $(which curl) ]] && apt install -y curl
    # import trap handler
    # source "$_coreDir/lib.trap.sh"
    wget -qO- https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/core/lib.trap.sh | bash
    # import variables
    # source "$_coreDir/_variables.sh"
    wget -qO- https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/core/_variables.sh | bash
    # import functions
    # source "$_coreDir/_helpers.sh"
    wget -qO- https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/core/_helpers.sh | bash
    CORE_SOURCE="${BASH_SOURCE[0]}"
}
