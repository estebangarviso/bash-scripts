#!/bin/bash

source "$(pwd)/core/lib.sh"

# Sanity check
_checkSanity

#
# FUNCTIONS
#

function _usage() {
    echo -n "$(basename $0) [OPTION]...

Script to create a CMS in a VPS.

Tested use in cloud-init script VM instance on Oracle Cloud

Infrastrucutre
  - Cloud
    - Oracle Cloud
      - Compute
        - VM
          - Instance

Image
  - Ubuntu 22.04 LTS

Requirements
  - Database name
  - User database name
  - User database password

Version $VERSION

    Options:
        -c, --cms                   CMS to install (default: prestashop)
        -ic, --iso-code             ISO code (default: en)
        -t, --timezone              Timezone (default: America/Toronto)
        -act, --activity            Activity (default: 17; 17 = Services)
        -d, --domain                Domain name (mandatory)
        -u, --user                  FTP user (mandatory) # TODO
        -sa, --super-admin          CMS super admin email (mandatory)
        -sap, --super-addmin-pass   CMS super admin password (If empty, auto-generated)
        -a, --admin                 CMS admin email (mandatory) # TODO
        -ap, --admin-pass           CMS admin password (If empty, auto-generated) # TODO

        -h, --help                  Display this help and exit
        -v, --version               Output version information and exit

    Examples:
        $(basename $0) --help

"
    _printPoweredBy
    exit 1
}

function processArgs() {
    # Parse Arguments
    for arg in "$@"; do
        case $arg in
        -c=* | --cms=*)
            CMS="${arg#*=}"
            ;;
        -ic=* | --iso-code=*)
            CMS_ISO_CODE="${arg#*=}"
            ;;
        -t=* | --timezone=*)
            CMS_TIMEZONE="${arg#*=}"
            ;;
        -co=* | --country=*)
            CMS_COUNTRY="${arg#*=}"
            ;;
        -ac=* | --activity=*)
            CMS_ACTIVITY="${arg#*=}"
            # Validate activity for Prestashop
            if [ "$CMS" = "prestashop" ]; then
                if [ "$CMS_ACTIVITY" -lt 1 ] || [ "$CMS_ACTIVITY" -gt 20 ]; then
                    _die "Activity must be between 1 and 20, check your activity number on file ./cloud/cms/prestashop/install.sh search \$list_activity"
                fi
            fi
            ;;
        -d=* | --domain=*)
            DOMAIN="${arg#*=}"
            # Validate domain eg. domain.com, sub.domain.com, domain.co.uk, domain.academy, domain.io
            if ! _validateDomain "$DOMAIN"; then
                _die "Invalid domain name"
            fi
            ;;
        # -u=* | --user=*)
        #     FTP_USER="${arg#*=}"
        #     ;;
        -sa=* | --super-admin=*)
            SUPER_ADMIN="${arg#*=}"
            # Validate email
            if ! _validateEmail "$SUPER_ADMIN"; then
                _die "Super admin email ${SUPER_ADMIN} is not valid"
            fi
            ;;
        -sap=* | --super-admin-pass=*)
            SUPER_ADMIN_PASS="${arg#*=}"
            ;;
        # -a=* | --admin=*)
        #     ADMIN="${arg#*=}"
        #     ;;
        # -ap=* | --admin-pass=*)
        #     ADMIN_PASS="${arg#*=}"
        #     ;;
        --debug)
            DEBUG=1
            ;;
        -h | --help)
            _usage
            ;;
        *)
            _usage
            ;;
        esac
    done
    if [[ ! " ${ALLOWED_CMS[@]} " =~ " ${CMS} " ]]; then
        _die "CMS not allowed!"
    fi
    if [ -z $DOMAIN ]; then
        _die "Domain name cannot be empty."
    fi
    if [ -z $SUPER_ADMIN ]; then
        SUPER_ADMIN="admin@$DOMAIN"
    fi
    # if [ -z $ADMIN ]; then
    #     _die "Admin email cannot be empty."
    # fi
    # if [ -z $FTP_USER ]; then
    #     FTP_USER=$(echo $DOMAIN | cut -d. -f1)
    # fi
    # local userCounter=0
    # if id -u "$FTP_USER" >/dev/null 2>&1; then
    #     while id -u "$FTP_USER$userCounter" >/dev/null 2>&1; do
    #         ((userCounter++))
    #     done
    #     FTP_USER="$FTP_USER$userCounter"
    # fi
    local tableSuffix="ps"
    if [ $CMS == "prestashop" ]; then
        CMS_DB_SUFFIX=$(echo $CMS | cut -c1-4)
        CMS_DB_TABLE_PREFIX=$(echo "$tableSuffix$(_generateRandomNumbers 3)_")
        # Refresh VERSION
        CMS_COMPRESSED_FILE="prestashop_${CMS_VERSION}.zip"
        CMS_DOWNLOAD_URL="https://download.prestashop.com/download/releases/${CMS_COMPRESSED_FILE}"
        CMS_INSTALL_ARGS=(
            --language=$CMS_ISO_CODE
            --timezone=$CMS_TIMEZONE
            --country=$CMS_COUNTRY
            --domain=$DOMAIN
            --prefix=$CMS_DB_TABLE_PREFIX
            --shop_name=$(_capitalize $DOMAIN)
            --shop_activity=$CMS_ACTIVITY
            --email=$SUPER_ADMIN
            --password=$SUPER_ADMIN_PASS
            --firstname="Admin"
            --lastname=$(_capitalize ${DOMAIN%%.*})
            --newsletter=0
            --ssl=1
        )
    fi
    # TODO: Add CMS_DB_SUFFIX and CMS_DB_TABLE_PREFIX for other CMS
    echo "${CMS_INSTALL_ARGS[@]}"
    exit 1
}

function generatePassword() {
    local length=${1:-12}
    echo "$(openssl rand -base64 $length)"
}

function generateRandomString() {
    local length=${1:-32}
    local randomString=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1)
    echo $randomString
}

function update() {
    _header "Updating system"
    if [ $OSTYPE == "linux-gnu" ]; then
        apt update -y && apt upgrade -y
        _header "Installing software-properties-common and apt-transport-https"
        apt install software-properties-common apt-transport-https -y
        _header "Import PHP Repository"
        add-apt-repository ppa:ondrej/php -y
        _header "Updating system again after adding PHP repository"
        apt update -y && apt upgrade -y
        _success "System updated"
    elif [ $OSTYPE == "darwin"* ]; then
        brew update
        brew upgrade
        _success "System updated"
    fi
}

function install() {
    _header "Installing CMS"
    # Check CMS Before Install
    _bold "Checking $CMS on the web..."
    _underline "Stay connected to the internet !"
    cd $WEB_DIR
    if [ -d "${WEB_DIR}/${DOMAIN}" ]; then
        _die "${WEB_DIR}/${DOMAIN} already exists! Please backup your data outside ${WEB_DIR} or remove it."
    fi
    if [ -d $CMS_COMPRESSED_FILE ]; then
        _warning "Deleting existing $CMS_COMPRESSED_FILE"
        rm -rf $CMS_COMPRESSED_FILE || {
            _die "rm ${CMS_COMPRESSED_FILE} failed !"
        }
    fi
    if ! _checkUrl -l=$CMS_DOWNLOAD_URL; then
        _die "Prestashop version $CMS_VERSION not found in $CMS_DOWNLOAD_URL, please check the version number or the URL."
    fi
    # Add PHP version to CMS dependencies
    for dep in $CMS_DEPENDENCIES; do
        if [[ $dep =~ ^php- ]]; then
            local newDep="${dep/php-/php$PHP_VERSION-}"
            CMS_DEPENDENCIES=$(echo ${CMS_DEPENDENCIES} | sed "s/$dep/$newDep/g")
        fi
        if [[ $dep =~ -php$ ]]; then
            local newDep="${dep/-php/-php$PHP_VERSION}"
            CMS_DEPENDENCIES=$(echo ${CMS_DEPENDENCIES} | sed "s/$dep/$newDep/g")
        fi
    done
    _success "Checking $CMS on the web... OK"
    # Installing packages
    _bold "Installing packages..."
    apt install -y $CMS_DEPENDENCIES
    _success "Packages installed!"

    # Installing and securing MariaDB
    source "$(pwd)/cloud/mariadb/install.sh"

    # Create database
    local databaseName=$(echo ${DOMAIN} | cut -d. -f1)
    source "$(pwd)/cloud/mariadb/create-database.sh" -db="${databaseName}${CMS_DB_SUFFIX}" -r
    _addMessage "Database: ${DB_NAME}" "success"
    _addMessage "User: ${DB_USER}" "success"
    _addMessage "Password: ${DB_PASS}" "success"

    # Set PHP version
    PHP_VERSION=$(php -v | head -n 1 | cut -d " " -f 2 | cut -d "." -f 1-2)
    PHP_VERSION_SHORT=$(echo $PHP_VERSION | sed 's/\([0-9]\)\.\([0-9]\).*/\1\2/')
    _success "PHP version: $PHP_VERSION"

    # Append database arguments to CMS_INSTALL_ARGS
    CMS_INSTALL_ARGS+=(
        --db_name=$DB_NAME
        --db_user=$DB_USER
        --db_password=$DB_PASS
    )
    # Install CMS
    _header "Installing $CMS through CLI"
    source "$(pwd)/cloud/$CMS/install.sh" --notci --ia $CMS_INSTALL_ARGS
    _success "$CMS installed through CLI successfully"

    # Set by operating system
    if [ "$OSTYPE" == "darwin"* ]; then
        if $(uname -m) == "arm64"; then
            ETC_DIR="/opt/homebrew/etc"
            WEB_DIR="/opt/homebrew/var/www"
            LOGS_DIR="/opt/homebrew/var/log"
        else
            ETC_DIR="/usr/local/etc"
            WEB_DIR="/usr/local/var/www"
            LOGS_DIR="/usr/local/var/log"
        fi
    fi
}

# TODO: Add feacture to access via FTP and SFTP for user
function createFTPUser() {
    # Check if user exists and create it if not
    if id -u $FTP_USER >/dev/null 2>&1; then
        _success "User $FTP_USER already exists"
    else
        # Create a standard user account
        _header "Creating user $FTP_USER"
        useradd -s /bin/bash -m -d /home/$FTP_USER $FTP_USER
        FTP_USER_PWD=$(generatePassword)
        echo "$FTP_USER:$FTP_USER_PWD" | chpasswd
        _success "User $FTP_USER created!"
        _addMessage "User: $FTP_USER" "success"
        _addMessage "Password: $FTP_USER_PWD" "success"
        _addMessage "Home: /home/$FTP_USER" "success"
    fi
}

function configurePhp() {
    _header "Configuring PHP"
    local phpIniFile="$ETC_DIR/php/$PHP_VERSION/fpm/php.ini"
    local phpFpmMpmFile="$ETC_DIR/php/$PHP_VERSION/fpm/pool.d/www.conf"
    # PHP configuration
    local date_timezone="UTC"
    local session_auto_start="off"
    local short_open_tag="off"
    local display_errors="off"
    local magic_quotes_gpc="off"

    local memory_limit="512M"
    local max_execution_time="300"
    local max_input_time="300"
    local upload_max_filesize="20M"
    local post_max_size="22M"
    local max_input_vars="20000"
    local allow_url_fopen="on"
    local safe_mode="off"
    local mod_rewrite="on"
    local mod_security="off"

    # Realpath cache
    local realpath_cache_size="4096K"
    local realpath_cache_ttl="600"

    # Opcache configuration
    # https://www.php.net/manual/en/opcache.installation.php
    local opcache_enabled="1"
    local opcache_enable_cli="0"
    local opcache_memory_consumption="256"
    local opcache_interned_strings_buffer="32"
    local opcache_max_accelerated_files="16229"
    local opcache_max_wasted_percentage="10"
    local opcache_revalidate_freq="10"
    local opcache_fast_shutdown="1"
    local opcache_enable_file_override="0"
    local opcache_max_file_size="0"

    _sed ";date.timezone =.*" "date.timezone = $date_timezone" "${phpIniFile}"
    _sed ";session.auto_start =.*" "session.auto_start = $session_auto_start" "${phpIniFile}"
    _sed ";short_open_tag =.*" "short_open_tag = $short_open_tag" "${phpIniFile}"
    _sed ";display_errors =.*" "display_errors = $display_errors" "${phpIniFile}"
    _sed ";magic_quotes_gpc =.*" "magic_quotes_gpc = $magic_quotes_gpc" "${phpIniFile}"
    _sed ";memory_limit =.*" "memory_limit = $memory_limit" "${phpIniFile}"
    _sed ";max_execution_time =.*" "max_execution_time = $max_execution_time" "${phpIniFile}"
    _sed ";max_input_time =.*" "max_input_time = $max_input_time" "${phpIniFile}"
    _sed ";upload_max_filesize =.*" "upload_max_filesize = $upload_max_filesize" "${phpIniFile}"
    _sed ";post_max_size =.*" "post_max_size = $post_max_size" "${phpIniFile}"
    _sed ";max_input_vars =.*" "max_input_vars = $max_input_vars" "${phpIniFile}"
    _sed ";allow_url_fopen =.*" "allow_url_fopen = $allow_url_fopen" "${phpIniFile}"
    _sed ";safe_mode =.*" "safe_mode = $safe_mode" "${phpIniFile}"
    _sed ";realpath_cache_size =.*" "realpath_cache_size = $realpath_cache_size" "${phpIniFile}"
    _sed ";realpath_cache_ttl =.*" "realpath_cache_ttl = $realpath_cache_ttl" "${phpIniFile}"
    _sed ";opcache.enable =.*" "opcache.enable = $opcache_enabled" "${phpIniFile}"
    _sed ";opcache.enable_cli =.*" "opcache.enable_cli = $opcache_enable_cli" "${phpIniFile}"
    _sed ";opcache.memory_consumption =.*" "opcache.memory_consumption = $opcache_memory_consumption" "${phpIniFile}"
    _sed ";opcache.interned_strings_buffer =.*" "opcache.interned_strings_buffer = $opcache_interned_strings_buffer" "${phpIniFile}"
    _sed ";opcache.max_accelerated_files =.*" "opcache.max_accelerated_files = $opcache_max_accelerated_files" "${phpIniFile}"
    _sed ";opcache.max_wasted_percentage =.*" "opcache.max_wasted_percentage = $opcache_max_wasted_percentage" "${phpIniFile}"
    _sed ";opcache.revalidate_freq =.*" "opcache.revalidate_freq = $opcache_revalidate_freq" "${phpIniFile}"
    _sed ";opcache.fast_shutdown =.*" "opcache.fast_shutdown = $opcache_fast_shutdown" "${phpIniFile}"
    _sed ";opcache.enable_file_override =.*" "opcache.enable_file_override = $opcache_enable_file_override" "${phpIniFile}"
    _sed ";opcache.max_file_size =.*" "opcache.max_file_size = $opcache_max_file_size" "${phpIniFile}"
}

function configurePhpFpm() {
    _header "Configuring PHP-FPM"

    local serverLimit="16"
    local maxClients="400"
    local startServers="3"
    local threadLimit="64"
    local threadsPerChild="25"
    local maxRequestWorkers="400"
    local maxConnectionsPerChild="0"

    # Configure mpm_event.conf file
    [-f $ETC_DIR/httpd/conf.modules.d/00-mpm.conf] && cat <<EOF >$ETC_DIR/httpd/conf.modules.d/00-mpm.conf
<IfModule mpm_*_module>
    ServerLimit             $serverLimit
    MaxClients              $maxClients
    StartServers            $startServers
    ThreadLimit             $threadLimit
    ThreadsPerChild         $threadsPerChild
    MaxRequestWorkers       $maxRequestWorkers
    MaxConnectionsPerChild  $maxConnectionsPerChild
</IfModule>
EOF
    # check if exist parameter inside file
    local phpFpmMpmDirPath=$(uname -s | grep -i "linux" >/dev/null && echo "$ETC_DIR/php/$PHP_VERSION/fpm/pool.d" || echo "$ETC_DIR/php/$PHP_VERSION/php-fpm.d")
    local phpFpmMpmFile=[-f "$phpFpmMpmDirPath"/www.conf] && echo "$phpFpmMpmDirPath"/www.conf || echo
    # backup old conf
    [ -f "$phpFpmMpmFile" ] && cp "$phpFpmMpmFile" "$phpFpmMpmFile".bak
    local pm_max_children="$serverLimit"
    [grep -q "pm.max_children" "$phpFpmMpmFile"] && _sed "pm.max_children =.*" "pm.max_children = $pm_max_children" "$phpFpmMpmFile" || echo "pm.max_children = $pm_max_children" >>"$phpFpmMpmFile"

    # Assign PHP-FPM variables to Nginx
    NGINX_CLIENT_MAX_BODY_SIZE="${post_max_size}"
}

function configureMariaDB() {
    _header "Configuring MariaDB"

    local mysqlConfFile="$ETC_DIR/my.cnf"
    if [ ! -f "$mysqlConfFile" ]; then
        mysqlConfFile="$ETC_DIR/mysql/my.cnf"
    fi
    if [ ! -f "$mysqlConfFile" ]; then
        mysqlConfFile="/usr/etc/my.cnf"
    fi
    if [ ! -f "$mysqlConfFile" ]; then
        mysqlConfFile="$HOME/.my.cnf"
    fi
    if [ ! -f "$mysqlConfFile" ]; then
        _error "Unable to find my.cnf. Check if MariaDB is installed and try again (if the problem persist, create a file manually in $ETC_DIR)."
        return 1
    fi

    # MariaDB configuration
    local query_cache_limit="128K"
    local query_cache_size="32M"
    local query_cache_type="ON"
    local table_open_cache="4000"
    local thread_cache_size="80"
    local host_cache_size="1000"

    # Sed command for Linux and Mac
    _sed "query_cache_limit.*" "query_cache_limit = $query_cache_limit" "$mysqlConfFile"
    _sed "query_cache_size.*" "query_cache_size = $query_cache_size" "$mysqlConfFile"
    _sed "query_cache_type.*" "query_cache_type = $query_cache_type" "$mysqlConfFile"
    _sed "table_open_cache.*" "table_open_cache = $table_open_cache" "$mysqlConfFile"
    _sed "thread_cache_size.*" "thread_cache_size = $thread_cache_size" "$mysqlConfFile"
    _sed "host_cache_size.*" "host_cache_size = $host_cache_size" "$mysqlConfFile"

}

function configureNginx() {
    _header "Configuring Nginx"
    # Create directories for Nginx
    mkdir -p $LOGS_DIR/nginx/logs/$DOMAIN
    mkdir -p $NGINX_AVAILABLE_VHOSTS_DIR
    mkdir -p $NGINX_ENABLED_VHOSTS_DIR
    mkdir -p $WEB_DIR/$DOMAIN
    # Create Nginx log files if they don't exist
    touch $LOGS_DIR/nginx/logs/$DOMAIN/access.log
    touch $LOGS_DIR/nginx/logs/$DOMAIN/error.log
    # Create Nginx config file and enable it
    source "$(pwd)/cloud/cms/$CMS/nginx.template.sh"
    # Enable vhost
    ln -s $NGINX_AVAILABLE_VHOSTS_DIR/$DOMAIN.conf $NGINX_ENABLED_VHOSTS_DIR/$DOMAIN.conf
}

function startServices() {
    # First stop all services to avoid conflicts
    _stopService nginx
    _stopService php$PHP_VERSION-fpm
    _stopService mariadb
    # Start Nginx, PHP and MariaDB
    _startService nginx
    _startService php$PHP_VERSION-fpm
    _startService mariadb
}

#
# MAIN
#
export LC_CTYPE=C
export LANG=C

ETC_DIR="/etc"
LOGS_DIR="/var/logs"
DEBUG=0 # 1|0
_debug set -x
VERSION="0.1.0"

DOMAIN=
ALLOWED_CMS=("prestashop") # TODO: add more CMS
WEB_DIR="/var/www"
WEB_USER="www-data"
FTP_USER=
FTP_USER_PWD=

CMS="prestashop"
CMS_INSTALL_ARGS=()
CMS_VERSION="1.7.6.9"
# mariadb-server and mariadb-client will be installed with mariadb/install.sh
CMS_DEPENDENCIES="nginx php-fpm php-common php-mysql php-gmp php-curl php-intl php-mbstring php-xmlrpc php-gd php-bcmath php-imap php-xml php-cli php-zip unzip wget git curl"
CMS_COMPRESSED_FILE="prestashop_${CMS_VERSION}.zip"
CMS_DOWNLOAD_URL="https://download.prestashop.com/download/releases/${CMS_COMPRESSED_FILE}"
CMS_ISO_CODE="en"
CMS_TIMEZONE="America/Toronto"
CMS_COUNTRY="ca"
CMS_DB_SUFFIX=
CMS_DB_TABLE_PREFIX=
CMS_ADMIN_DIRNAME="admin$(generateRandomString 10)"
CMS_ACTIVITY=17
SUPER_ADMIN=
SUPER_ADMIN_PASS="$(generatePassword)"
ADMIN=
ADMIN_PASS="$(generatePassword)"

NGINX_AVAILABLE_VHOSTS_DIR="${ETC_DIR}/nginx/sites-available"
NGINX_ENABLED_VHOSTS_DIR="${ETC_DIR}/nginx/sites-enabled"
NGINX_CLIENT_MAX_BODY_SIZE="22M"

DB_NAME=
DB_USER=
DB_PASS=

PHP_VERSION="7.2" # Recommended PHP version for PrestaShop 1.7.6.9
PHP_VERSION_SHORT=

export DEBIAN_FRONTEND=noninteractive

function main() {
    [[ $# -lt 1 ]] && _usage
    # Process arguments
    processArgs "$@"
    # (L)
    # Update VM
    update
    # # Create User
    # createFTPUser
    # Install
    install
    # Configure Nginx (E)
    configureNginx
    # Configure MariaDB (M)
    configureMariaDB
    # Configure PHP (P)
    configurePhp
    # Start services
    startServices
}

main "$@"
_debug set +x
