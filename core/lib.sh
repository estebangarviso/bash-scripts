CORE_SOURCE=
if [ -z $CORE_SOURCE ]; then
    # import variables
    source "$(pwd)/core/_variables.sh"
    # import functions
    source "$(pwd)/core/_helpers.sh"
    # import trap handler
    source "$(pwd)/core/_errorHandling.sh"
    CORE_SOURCE="${BASH_SOURCE[0]}"
fi
