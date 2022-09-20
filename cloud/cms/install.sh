#!/bin/bash

# source "../../core/lib.sh"
bash -c "$(curl -L https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/core/lib.sh)"

# Sanity check
_checkRoot

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
        -d, --domain                Domain name (mandatory)
        -u, --u                     OS user (default: domain without TLD)
        -sa, --super-admin          CMS super admin email (mandatory)
        -sap, --super-addmin-pass   CMS super admin password (If empty, auto-generated)
        -a, --admin                 CMS admin email (mandatory)
        -ap, --admin-pass           CMS admin password (If empty, auto-generated)

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
        -d=* | --domain=*)
            DOMAIN="${arg#*=}"
            ;;
        -u=* | --user=*)
            USER="${arg#*=}"
            ;;
        -sa=* | --super-admin=*)
            SUPER_ADMIN="${arg#*=}"
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
    [[ ! " ${ALLOWED_CMS[@]} " =~ " ${CMS} " ]] && _die "CMS not allowed!"
    [[ -z $DOMAIN ]] && _die "Domain name cannot be empty."
    [[ -z $SUPER_ADMIN ]] && _die "Super admin email cannot be empty."
    [[ -z $ADMIN ]] && _die "Admin email cannot be empty."
    [[ -z $USER ]] && USER=$(echo $DOMAIN | cut -d. -f1)
    local userCounter=0
    id -u "$USER" >/dev/null 2>&1 && {
        while id -u "$USER$userCounter" >/dev/null 2>&1; do
            ((userCounter++))
        done
        USER="$USER$userCounter"
    }
    local tableSuffix="ps"
    [[ $CMS == "prestashop" ]] && {
        DB_SUFFIX=$(echo $CMS | cut -c1-4)
        DB_TABLE_PREFIX=$(echo "$tableSuffix$(_generateRandomNumbers 3)_")
    }
    # TODO: Add DB_SUFFIX and DB_TABLE_PREFIX for other CMS
}

function generatePassword() {
    local length=$1
    [[ -z "$length" ]] && length=12
    echo "$(openssl rand -base64 $length)"
}

function generateRandomString() {
    local length=$1
    if [ -z "$length" ]; then
        length=32
    fi
    local randomString=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1)
    echo $randomString
}

function update() {
    _header "Updating system"
    apt update -y && apt upgrade -y
    _success "System updated!"
}

function install() {
    _header "Installing $CMS"

    # Installing packages
    case $CMS in
    prestashop)
        # mariadb-server and mariadb-client were installed in mariadb/install.sh
        apt install -y
        ;;
    *)
        _die "CMS not supported"
        # Checked CMS on processArgs function
        ;;
    esac
    _success "Packages installed!"

    # Installing and securing MariaDB
    # source "$_rootDir/mariadb/install.sh"
    bash -c "$(curl -L https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/cloud/mariadb/install.sh)"

    # Create database
    local databaseName=$(echo $DOMAIN | cut -d. -f1)
    # source "$_rootDir/mariadb/create-database.sh" -db="${databaseName}${DB_SUFFIX}" -r
    # wget -qO- https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/cloud/mariadb/create-database.sh | bash -db="${databaseName}${DB_SUFFIX}" -r
    bash -c "$(curl -L https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/cloud/mariadb/create-database.sh | bash -db="${databaseName}${DB_SUFFIX}" -r)"
    _addMessage "<h3>Database</h3>" "success"
    _addMessage "Host: localhost" "success"
    _addMessage "Database: ${DB_NAME}" "success"
    _addMessage "User: ${DB_USER}" "success"
    _addMessage "Password: ${DB_PASS}" "success"

    # Set PHP version
    PHP_VERSION=$(php -v | head -n 1 | cut -d " " -f 2 | cut -d "." -f 1-2)
    PHP_VERSION_SHORT=$(echo $PHP_VERSION | sed 's/\([0-9]\)\.\([0-9]\).*/\1\2/')
    _success "PHP version: $PHP_VERSION"

    # Set by operating system
    [["$OSTYPE" == "darwin"*]] && {
        if $(uname -m) == "arm64"; then
            ETC_DIR="/opt/homebrew/etc"
        else
            ETC_DIR="/usr/local/etc"
        fi
    }
    # [[ "$OSTYPE" == "linux"* ]] && ETC_DIR="/etc" # Default value
}

# TODO: Add feacture to access via FTP and SFTP for user
function createUser() {
    # Check if user exists and create it if not
    if id -u $USER >/dev/null 2>&1; then
        _success "User $USER already exists"
    else
        # Create a standard user account
        _header "Creating user $USER"
        useradd -s /bin/bash -m -d /home/$USER $USER
        USER_PWD=$(generatePassword)
        echo "$USER:$USER_PWD" | chpasswd
        _success "User $USER created!"
        _addMessage "<h3>User</h3>" "success"
        _addMessage "User: $USER" "success"
        _addMessage "Password: $USER_PWD" "success"
        _addMessage "Home: /home/$USER" "success"
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

    _sed ";date.timezone =.*" "date.timezone = $date_timezone" "$phpIniFile"
    _sed ";session.auto_start =.*" "session.auto_start = $session_auto_start" "$phpIniFile"
    _sed ";short_open_tag =.*" "short_open_tag = $short_open_tag" "$phpIniFile"
    _sed ";display_errors =.*" "display_errors = $display_errors" "$phpIniFile"
    _sed ";magic_quotes_gpc =.*" "magic_quotes_gpc = $magic_quotes_gpc" "$phpIniFile"
    _sed ";memory_limit =.*" "memory_limit = $memory_limit" "$phpIniFile"
    _sed ";max_execution_time =.*" "max_execution_time = $max_execution_time" "$phpIniFile"
    _sed ";max_input_time =.*" "max_input_time = $max_input_time" "$phpIniFile"
    _sed ";upload_max_filesize =.*" "upload_max_filesize = $upload_max_filesize" "$phpIniFile"
    _sed ";post_max_size =.*" "post_max_size = $post_max_size" "$phpIniFile"
    _sed ";max_input_vars =.*" "max_input_vars = $max_input_vars" "$phpIniFile"
    _sed ";allow_url_fopen =.*" "allow_url_fopen = $allow_url_fopen" "$phpIniFile"
    _sed ";safe_mode =.*" "safe_mode = $safe_mode" "$phpIniFile"
    _sed ";realpath_cache_size =.*" "realpath_cache_size = $realpath_cache_size" "$phpIniFile"
    _sed ";realpath_cache_ttl =.*" "realpath_cache_ttl = $realpath_cache_ttl" "$phpIniFile"
    _sed ";opcache.enable =.*" "opcache.enable = $opcache_enabled" "$phpIniFile"
    _sed ";opcache.enable_cli =.*" "opcache.enable_cli = $opcache_enable_cli" "$phpIniFile"
    _sed ";opcache.memory_consumption =.*" "opcache.memory_consumption = $opcache_memory_consumption" "$phpIniFile"
    _sed ";opcache.interned_strings_buffer =.*" "opcache.interned_strings_buffer = $opcache_interned_strings_buffer" "$phpIniFile"
    _sed ";opcache.max_accelerated_files =.*" "opcache.max_accelerated_files = $opcache_max_accelerated_files" "$phpIniFile"
    _sed ";opcache.max_wasted_percentage =.*" "opcache.max_wasted_percentage = $opcache_max_wasted_percentage" "$phpIniFile"
    _sed ";opcache.revalidate_freq =.*" "opcache.revalidate_freq = $opcache_revalidate_freq" "$phpIniFile"
    _sed ";opcache.fast_shutdown =.*" "opcache.fast_shutdown = $opcache_fast_shutdown" "$phpIniFile"
    _sed ";opcache.enable_file_override =.*" "opcache.enable_file_override = $opcache_enable_file_override" "$phpIniFile"
    _sed ";opcache.max_file_size =.*" "opcache.max_file_size = $opcache_max_file_size" "$phpIniFile"
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

}

function configureMariaDB() {
    _header "Configuring MariaDB"

    local mysqlConfFile="$ETC_DIR/my.cnf"
    test -f "$mysqlConfFile" || mysqlConfFile="$ETC_DIR/mysql/my.cnf"
    test -f "$mysqlConfFile" || mysqlConfFile="/usr/etc/my.cnf"
    test -f "$mysqlConfFile" || mysqlConfFile="$HOME/.my.cnf"
    test -f "$mysqlConfFile" || {
        _addMessage "Unable to find my.cnf. Check if MariaDB is installed and try again (if the problem persist, create a file manually in $ETC_DIR)." "error"
        return 1
    }

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
    # source "./$CMS/nginx.template.sh"
    wget -qO- https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/cloud/cms/prestashop/nginx.template.sh | bash
    # Enable vhost
    ln -s $NGINX_AVAILABLE_VHOSTS_DIR/$DOMAIN.conf $NGINX_ENABLED_VHOSTS_DIR/$DOMAIN.conf
}

function startServices() {
    case "$OSTYPE" in
    linux*)
        # start Nginx, PHP and MariaDB
        systemctl start nginx
        systemctl start php$PHP_VERSION-fpm
        systemctl start mariadb
        ;;
    darwin*)
        # Check if brew is installed
        if command -v brew &>/dev/null; then
            brew services restart "php@$PHP_VERSION"
            brew services restart nginx
            brew services restart mariadb
        else
            echo "Brew is not installed"
            _addMessage "Brew is not installed" "error"
            return 1
        fi

        ;;
    *)
        echo "Unknown OS"
        _addMessage "Unknown OS" "error"
        return 1
        ;;
    esac
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
# USER=
# USER_PWD=

CMS="prestashop"
CMS_VERSION="1.7.6.9"
CMS_DEPENDENCIES="nginx php-fpm php-common php-mysql php-gmp php-curl php-intl php-mbstring php-xmlrpc php-gd php-bcmath php-imap php-xml php-cli php-zip unzip wget git curl"
ADMIN_DIRNAME="admin$(generateRandomString 10)"
SUPER_ADMIN=
SUPER_ADMIN_PASS="$(generatePassword)"
# ADMIN=
# ADMIN_PASS=

NGINX_AVAILABLE_VHOSTS_DIR="$ETC_DIR/nginx/sites-available"
NGINX_ENABLED_VHOSTS_DIR="$ETC_DIR/nginx/sites-enabled"

PHP_VERSION="7.4"
PHP_VERSION_SHORT=

DB_SUFFIX=
DB_TABLE_PREFIX=

export DEBIAN_FRONTEND=noninteractive

function main() {
    [[ $# -lt 1 ]] && _usage
    # Process arguments
    processArgs "$@"

    # Update VM
    update

    # # Create User
    # createUser

    # Install (L)
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
