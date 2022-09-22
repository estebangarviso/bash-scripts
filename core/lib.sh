CORE_SOURCE=
if [ -z $CORE_SOURCE ]; then
    # import trap handler
    source "$(pwd)/core/lib.trap.sh"
    # import variables
    source "$(pwd)/core/_variables.sh"
    # import functions
    source "$(pwd)/core/_helpers.sh"
    CORE_SOURCE="${BASH_SOURCE[0]}"
fi
