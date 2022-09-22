#!/bin/bash

source "$(pwd)/core/lib.sh"

# Sanity check
_checkRoot

#
# FUNCTIONS
#

function _usage() {
    echo -n "$(basename $0) [OPTION]...

Automatically create a CMS Prestashop ecommerce.
Version $VERSION

Pre-requisites:
    - A running MariaDB server
    - A running Nginx server
    - A running PHP-FPM server

    Prestashop Install CLI options (available arguments (PrestaShop version 1.7.6.9):
        --l, --language                     Language (default: en)
        --all_languages                     Install all languages (default: 0)
        --t, --timezone                     Shop timezone (default: Europe/Paris)
        --base_uri                          Base URI (default: /)
        --http_host, --domain               Domain name (default: localhost)
        --db_host                           Domain name host (default: localhost)
        --h, --db_server                    Database server (default: localhost)
        --u, --db_user                      Database user (default: root)
        --p, --db_password                  Database password (default none)
        --d, --db_name                      Database name (default: prestashop)
        --prefix                            Database prefix (default: ps_)
        --engine                            Database engine (default: InnoDB)
        --shop_name                         Shop name (default: Prestashop)
        --shop_activity, --activity         Shop activity (default: 0)
        --shop_country, --country           Shop country (default: fr)
        --admin_firstname, firstname        Admin firstname (default: John)
        --admin_lastname, lastname          Admin lastname (default: Doe)
        --admin_password, --password        Admin password (default: admin)
        --admin_email, --email              Admin email (default: pub@prestashop.com)
        --show_license, --license           Show license (default: 0)
        --newsletter                        Get news from PrestaShop (default: 0)
        --theme                             Theme (default: classic)
        --enable_ssl, --ssl                 Enable SSL (default: 0)
        --rewrite_engine                    Enable rewrite engine (default: 1)

    Other options:
        -ia, --install-args             Install arguments (default: none)
        -notci, --not-check-install     Do not check if the CMS if was checked before
        -h, --help                      Display this help and exit
        -v, --version                   Output version information and exit

    Examples:
        $(basename $0) --language=en --timezone=Europe/Paris --domain=virtualsense.cl --db_user=root --db_password=123456 --db_name=prestashop --prefix=ps_ --shop_name=VirtualSense --shop_activity=0 --shop_country=cl --admin_firstname=John --admin_lastname=Doe --admin_password=123456

"
    _printPoweredBy
    exit 1
}

function availableArguments() {
    echo -n "Available arguments (PrestaShop version 1.7.6.9):
    through bash script, you must pass the following arguments like so:
    --language=\"en\" -t=\"Europe/Paris\" --db_name=\"prestashop\" --db_user=\"prestashop\" --db_password=\"prestashop\" --db_host=\"localhost\" --db_port=\"3306\" --db_prefix=\"ps_\" --domain=\"demo.com\"
    
    PHP arguments, /var/www/yourdomain/install/classes/datas.php line 30
    #     protected static $available_args = array(
    #     'step' => array(
    #         'name' => 'step',
    #         'default' => 'all',
    #         'validate' => 'isGenericName',
    #         'help' => 'all / database,fixtures,theme,modules,addons_modules',
    #     ),
    #     'language' => array(
    #         'default' => 'en',
    #         'validate' => 'isLanguageIsoCode',
    #         'alias' => 'l',
    #         'help' => 'language iso code',
    #     ),
    #     'all_languages' => array(
    #         'default' => '0',
    #         'validate' => 'isInt',
    #         'alias' => 'l',
    #         'help' => 'install all available languages',
    #     ),
    #     'timezone' => array(
    #         'default' => 'Europe/Paris',
    #         'alias' => 't',
    #     ),
    #     'base_uri' => array(
    #         'name' => 'base_uri',
    #         'validate' => 'isUrl',
    #         'default' => '/',
    #     ),
    #     'http_host' => array(
    #         'name' => 'domain',
    #         'validate' => 'isGenericName',
    #         'default' => 'localhost',
    #     ),
    #     'database_server' => array(
    #         'name' => 'db_server',
    #         'default' => 'localhost',
    #         'validate' => 'isGenericName',
    #         'alias' => 'h',
    #     ),
    #     'database_login' => array(
    #         'name' => 'db_user',
    #         'alias' => 'u',
    #         'default' => 'root',
    #         'validate' => 'isGenericName',
    #     ),
    #     'database_password' => array(
    #         'name' => 'db_password',
    #         'alias' => 'p',
    #         'default' => '',
    #     ),
    #     'database_name' => array(
    #         'name' => 'db_name',
    #         'alias' => 'd',
    #         'default' => 'prestashop',
    #         'validate' => 'isGenericName',
    #     ),
    #     'database_clear' => array(
    #         'name' => 'db_clear',
    #         'default' => '1',
    #         'validate' => 'isInt',
    #         'help' => 'Drop existing tables',
    #     ),
    #     'database_create' => array(
    #         'name' => 'db_create',
    #         'default' => '0',
    #         'validate' => 'isInt',
    #         'help' => 'Create the database if not exist',
    #     ),
    #     'database_prefix' => array(
    #         'name' => 'prefix',
    #         'default' => 'ps_',
    #         'validate' => 'isGenericName',
    #     ),
    #     'database_engine' => array(
    #         'name' => 'engine',
    #         'validate' => 'isMySQLEngine',
    #         'default' => 'InnoDB',
    #         'help' => 'InnoDB/MyISAM',
    #     ),
    #     'shop_name' => array(
    #         'name' => 'name',
    #         'validate' => 'isGenericName',
    #         'default' => 'PrestaShop',
    #     ),
    #     'shop_activity'    => array(
    #         'name' => 'activity',
    #         'default' => 0,
    #         'validate' => 'isInt',
    #     ),
    #     'shop_country' => array(
    #         'name' => 'country',
    #         'validate' => 'isLanguageIsoCode',
    #         'default' => 'fr',
    #     ),
    #     'admin_firstname' => array(
    #         'name' => 'firstname',
    #         'validate' => 'isName',
    #         'default' => 'John',
    #     ),
    #     'admin_lastname'    => array(
    #         'name' => 'lastname',
    #         'validate' => 'isName',
    #         'default' => 'Doe',
    #     ),
    #     'admin_password' => array(
    #         'name' => 'password',
    #         'validate' => 'isPasswd',
    #         'default' => '0123456789',
    #     ),
    #     'admin_email' => array(
    #         'name' => 'email',
    #         'validate' => 'isEmail',
    #         'default' => 'pub@prestashop.com',
    #     ),
    #     'show_license' => array(
    #         'name' => 'license',
    #         'default' => 0,
    #         'help' => 'show PrestaShop license',
    #     ),
    #     'newsletter' => array(
    #         'name' => 'newsletter',
    #         'default' => 1,
    #         'help' => 'get news from PrestaShop',
    #     ),
    #     'theme' => array(
    #         'name' => 'theme',
    #         'default' => '',
    #     ),
    #     'enable_ssl' => array(
    #         'name' => 'ssl',
    #         'default' => 0,
    #         'help' => 'enable SSL for PrestaShop',
    #     ),
    #     'rewrite_engine' => array(
    #         'name' => 'rewrite',
    #         'default' => 1,
    #         'help' => 'enable rewrite engine for PrestaShop',
    #     ),
    # );
    "
}

function processArgs() {
    # Parse Arguments
    for arg in "$@"; do
        case $arg in
        --debug)
            DEBUG=1
            ;;
        -ia | --install-args)
            while ["$1" != ""]; do
                INSTALL_ARGS=$INSTALL_ARGS$1" "
                shift
            done
            ;;
        -notci | --not-check-install)
            CHECK_INSTALL=0
            ;;
        -h | --help)
            _usage
            ;;
        -v | --version)
            _version
            ;;
        *)
            _usage
            ;;
        esac
    done
    if [[ -z $INSTALL_ARGS ]]; then
        _die "No arguments provided"
    fi
}

function generatePassword() {
    echo "$(openssl rand -base64 12)"
}

function getPSZipFile() {
    echo "prestashop_${PS_VERSION}.zip"
}

function install() {
    local zipFile=getPSZipFile
    cd $WEB_DIR
    if [ $CHECK_INSTALL -eq 1 ]; then
        if [ -d "${WEB_DIR}/${DOMAIN}" ]; then
            _die "${WEB_DIR}/${DOMAIN} already exists! Please backup your data outside ${WEB_DIR} or remove it."
        fi
        if [ -d $zipFile ]; then
            _warning "Deleting existing $zipFile"
            rm -rf $zipFile || {
                _die "rm ${zipFile} failed !"
            }
        fi
        if ! _checkUrl "https://download.prestashop.com/download/releases/${zipFile}"; then
            _die "Prestashop version $PS_VERSION not found !"
        fi
    fi
    mkdir $DOMAIN
    cd $DOMAIN
    _bold "Downloading from https://download.prestashop.com/download/releases to "${WEB_DIR}/${DOMAIN}" ..."
    wget -q "https://download.prestashop.com/download/releases/${zipFile}" || {
        _die "wget failed !"
    }
    _success "Extracting ${zipFile} ..."
    unzip -q $zipFile
    rm -rf $zipFile

    if [ -f prestashop.zip ]; then
        unzip -o -q prestashop.zip
        rm -rf prestashop.zip
        rm -rf index.php
        rm -rf Install_PrestaShop.html
    fi

    # Move all content inside prestashop folder to "${WEB_DIR}/${DOMAIN}" and remove empty prestashop folder
    mv "${WEB_DIR}/${DOMAIN}"/prestashop/* "${WEB_DIR}/${DOMAIN}"
    rm -rf "${WEB_DIR}/${DOMAIN}"/prestashop

    # Add write permissions for config files
    find "${WEB_DIR}/${DOMAIN}/" -exec chown $WEB_USER:$WEB_USER {} \;
    local installDir="${WEB_DIR}/${DOMAIN}/install"
    php "${WEB_DIR}/${DOMAIN}/install/index_cli.php" "${INSTALL_ARGS}" && {
        _success "Prestashop installed successfully !"
        _success "You can access your store at http://${DOMAIN}/"
        _success "Admin panel is at http://${DOMAIN}/admin"
        _success "Admin login: ${ADMIN_EMAIL}"
        _success "Admin password: ${ADMIN_PASSWORD}"
    } || {
        _die "Prestashop installation failed !"
    }
    if [ -d $installDir ]; then
        _warning "Deleting existing $installDir"
        rm -rf $installDir || {
            _die "rm ${installDir} failed !"
        }
    fi
    # chmod folders to 755 and files to 644
    find "${WEB_DIR}/${DOMAIN}/" -type d -exec chmod 0755 {} \;
    find "${WEB_DIR}/${DOMAIN}/" -type f -exec chmod 0644 {} \;
}

#
# MAIN
#
export LC_CTYPE=C
export LANG=C

DEBUG=0 # 1|0
_debug set -x
VERSION="0.1.0"

PS_VERSION="1.7.6.9"
CHECK_INSTALL=1
# Store domain will be used directory name on WEB_DIR and as domain name for the store
DOMAIN=
INSTALL_ARGS=
WEB_DIR="/var/www"
WEB_USER="www-data"

function main() {
    # Process arguments
    processArgs "$@"
    # Install
    install
}

main "$@"

_debug set +x
