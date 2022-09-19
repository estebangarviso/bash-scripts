_coreDir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# import trap handler
source "$_coreDir/lib.trap.sh"
# import variables
source "$_coreDir/_variables.sh"
# import functions
source "$_coreDir/_helpers.sh"

CORE_SOURCE="${BASH_SOURCE[0]}"