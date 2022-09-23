#!/bin/bash

source "$(pwd)/core/lib.sh"

# Sanity check
_checkSanity

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
        --language                          Language (default: en)
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
    #     protected static \$available_args = array(
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
    PHP List of activities, /var/www/yourdomain/install/controllers/http/configure.php
    #     \$list_activities = array(
    #     1 => \$this->translator->trans('Lingerie and Adult', array(), 'Install'),
    #     2 => \$this->translator->trans('Animals and Pets', array(), 'Install'),
    #     3 => \$this->translator->trans('Art and Culture', array(), 'Install'),
    #     4 => \$this->translator->trans('Babies', array(), 'Install'),
    #     5 => \$this->translator->trans('Beauty and Personal Care', array(), 'Install'),
    #     6 => \$this->translator->trans('Cars', array(), 'Install'),
    #     7 => \$this->translator->trans('Computer Hardware and Software', array(), 'Install'),
    #     8 => \$this->translator->trans('Download', array(), 'Install'),
    #     9 => \$this->translator->trans('Fashion and accessories', array(), 'Install'),
    #     10 => \$this->translator->trans('Flowers, Gifts and Crafts', array(), 'Install'),
    #     11 => \$this->translator->trans('Food and beverage', array(), 'Install'),
    #     12 => \$this->translator->trans('HiFi, Photo and Video', array(), 'Install'),
    #     13 => \$this->translator->trans('Home and Garden', array(), 'Install'),
    #     14 => \$this->translator->trans('Home Appliances', array(), 'Install'),
    #     15 => \$this->translator->trans('Jewelry', array(), 'Install'),
    #     16 => \$this->translator->trans('Mobile and Telecom', array(), 'Install'),
    #     17 => \$this->translator->trans('Services', array(), 'Install'),
    #     18 => \$this->translator->trans('Shoes and accessories', array(), 'Install'),
    #     19 => \$this->translator->trans('Sports and Entertainment', array(), 'Install'),
    #     20 => \$this->translator->trans('Travel', array(), 'Install'),
    # );
    Web Scrapping of List of countries from installer
    # \$list_countries = array(
    #     'fr' => 'Francia',
    #     'es' => 'España',
    #     'us' => 'Estados Unidos',
    #     'gb' => 'Reino Unido',
    #     'it' => 'Italia',
    #     'de' => 'Alemania',
    #     'nl' => 'Países Bajos',
    #     'pl' => 'Polonia',
    #     'id' => 'Indonesia',
    #     'be' => 'Bélgica',
    #     'br' => 'Brasil',
    #     'se' => 'Suecia',
    #     'ca' => 'Canadá',
    #     'ru' => 'Rusia',
    #     'cn' => 'China',
    #     'af' => 'Afganistán',
    #     'al' => 'Albania',
    #     'ad' => 'Andorra',
    #     'ao' => 'Angola',
    #     'ai' => 'Anguila',
    #     'ag' => 'Antigua y Barbuda',
    #     'aq' => 'Antártida',
    #     'sa' => 'Arabia Saudí',
    #     'dz' => 'Argelia',
    #     'ar' => 'Argentina',
    #     'am' => 'Armenia',
    #     'aw' => 'Aruba',
    #     'au' => 'Australia',
    #     'at' => 'Austria',
    #     'az' => 'Azerbaiyán',
    #     'bs' => 'Bahamas',
    #     'bd' => 'Bangladés',
    #     'bb' => 'Barbados',
    #     'bh' => 'Baréin',
    #     'bz' => 'Belice',
    #     'bj' => 'Benín',
    #     'bm' => 'Bermudas',
    #     'by' => 'Bielorrusia',
    #     'bo' => 'Bolivia',
    #     'ba' => 'Bosnia y Herzegovina',
    #     'bw' => 'Botsuana',
    #     'bn' => 'Brunéi',
    #     'bg' => 'Bulgaria',
    #     'bf' => 'Burkina Faso',
    #     'bi' => 'Burundi',
    #     'bt' => 'Bután',
    #     'cv' => 'Cabo Verde',
    #     'kh' => 'Camboya',
    #     'cm' => 'Camerún',
    #     'qa' => 'Catar',
    #     'td' => 'Chad',
    #     'cz' => 'Chequia',
    #     'cl' => 'Chile',
    #     'cy' => 'Chipre',
    #     'va' => 'Ciudad del Vaticano',
    #     'co' => 'Colombia',
    #     'km' => 'Comoras',
    #     'cg' => 'Congo',
    #     'kp' => 'Corea del Norte',
    #     'kr' => 'Corea del Sur',
    #     'cr' => 'Costa Rica',
    #     'hr' => 'Croacia',
    #     'cu' => 'Cuba',
    #     'ci' => 'Côte d’Ivoire',
    #     'dk' => 'Dinamarca',
    #     'dm' => 'Dominica',
    #     'ec' => 'Ecuador',
    #     'eg' => 'Egipto',
    #     'sv' => 'El Salvador',
    #     'ae' => 'Emiratos Árabes Unidos',
    #     'er' => 'Eritrea',
    #     'sk' => 'Eslovaquia',
    #     'si' => 'Eslovenia',
    #     'ee' => 'Estonia',
    #     'sz' => 'Esuatini',
    #     'et' => 'Etiopía',
    #     'ph' => 'Filipinas',
    #     'fi' => 'Finlandia',
    #     'fj' => 'Fiyi',
    #     'ga' => 'Gabón',
    #     'gm' => 'Gambia',
    #     'ge' => 'Georgia',
    #     'gh' => 'Ghana',
    #     'gi' => 'Gibraltar',
    #     'gd' => 'Granada',
    #     'gr' => 'Grecia',
    #     'gl' => 'Groenlandia',
    #     'gp' => 'Guadalupe',
    #     'gu' => 'Guam',
    #     'gt' => 'Guatemala',
    #     'gf' => 'Guayana Francesa',
    #     'gg' => 'Guernsey',
    #     'gn' => 'Guinea',
    #     'gq' => 'Guinea Ecuatorial',
    #     'gw' => 'Guinea-Bisáu',
    #     'gy' => 'Guyana',
    #     'ht' => 'Haití',
    #     'hn' => 'Honduras',
    #     'hu' => 'Hungría',
    #     'in' => 'India',
    #     'iq' => 'Irak',
    #     'ie' => 'Irlanda',
    #     'ir' => 'Irán',
    #     'nf' => 'Isla Norfolk',
    #     'im' => 'Isla de Man',
    #     'cx' => 'Isla de Navidad',
    #     'is' => 'Islandia',
    #     'ky' => 'Islas Caimán',
    #     'cc' => 'Islas Cocos',
    #     'ck' => 'Islas Cook',
    #     'fo' => 'Islas Feroe',
    #     'gs' => 'Islas Georgia del Sur y Sandwich del Sur',
    #     'fk' => 'Islas Malvinas',
    #     'mp' => 'Islas Marianas del Norte',
    #     'mh' => 'Islas Marshall',
    #     'pn' => 'Islas Pitcairn',
    #     'sb' => 'Islas Salomón',
    #     'tc' => 'Islas Turcas y Caicos',
    #     'vg' => 'Islas Vírgenes Británicas',
    #     'vi' => 'Islas Vírgenes de EE. UU.',
    #     'ax' => 'Islas Åland',
    #     'il' => 'Israel',
    #     'jm' => 'Jamaica',
    #     'jp' => 'Japón',
    #     'je' => 'Jersey',
    #     'jo' => 'Jordania',
    #     'kz' => 'Kazajistán',
    #     'ke' => 'Kenia',
    #     'kg' => 'Kirguistán',
    #     'ki' => 'Kiribati',
    #     'kw' => 'Kuwait',
    #     'la' => 'Laos',
    #     'ls' => 'Lesoto',
    #     'lv' => 'Letonia',
    #     'lr' => 'Liberia',
    #     'ly' => 'Libia',
    #     'li' => 'Liechtenstein',
    #     'lt' => 'Lituania',
    #     'lu' => 'Luxemburgo',
    #     'lb' => 'Líbano',
    #     'mk' => 'Macedonia del Norte',
    #     'mg' => 'Madagascar',
    #     'my' => 'Malasia',
    #     'mw' => 'Malaui',
    #     'mv' => 'Maldivas',
    #     'ml' => 'Mali',
    #     'mt' => 'Malta',
    #     'ma' => 'Marruecos',
    #     'mq' => 'Martinica',
    #     'mu' => 'Mauricio',
    #     'mr' => 'Mauritania',
    #     'yt' => 'Mayotte',
    #     'fm' => 'Micronesia',
    #     'md' => 'Moldavia',
    #     'mn' => 'Mongolia',
    #     'me' => 'Montenegro',
    #     'ms' => 'Montserrat',
    #     'mz' => 'Mozambique',
    #     'mm' => 'Myanmar (Birmania)',
    #     'mx' => 'México',
    #     'mc' => 'Mónaco',
    #     'na' => 'Namibia',
    #     'nr' => 'Nauru',
    #     'np' => 'Nepal',
    #     'ni' => 'Nicaragua',
    #     'ng' => 'Nigeria',
    #     'nu' => 'Niue',
    #     'no' => 'Noruega',
    #     'nc' => 'Nueva Caledonia',
    #     'nz' => 'Nueva Zelanda',
    #     'ne' => 'Níger',
    #     'om' => 'Omán',
    #     'pk' => 'Pakistán',
    #     'pw' => 'Palaos',
    #     'pa' => 'Panamá',
    #     'pg' => 'Papúa Nueva Guinea',
    #     'py' => 'Paraguay',
    #     'pe' => 'Perú',
    #     'pf' => 'Polinesia Francesa',
    #     'pt' => 'Portugal',
    #     'pr' => 'Puerto Rico',
    #     'hk' => 'RAE de Hong Kong (China)',
    #     'mo' => 'RAE de Macao (China)',
    #     'cf' => 'República Centroafricana',
    #     'cd' => 'República Democrática del Congo',
    #     'do' => 'República Dominicana',
    #     're' => 'Reunión',
    #     'rw' => 'Ruanda',
    #     'ro' => 'Rumanía',
    #     'ws' => 'Samoa',
    #     'as' => 'Samoa Americana',
    #     'bl' => 'San Bartolomé',
    #     'kn' => 'San Cristóbal y Nieves',
    #     'sm' => 'San Marino',
    #     'mf' => 'San Martín',
    #     'pm' => 'San Pedro y Miquelón',
    #     'vc' => 'San Vicente y las Granadinas',
    #     'lc' => 'Santa Lucía',
    #     'st' => 'Santo Tomé y Príncipe',
    #     'sn' => 'Senegal',
    #     'rs' => 'Serbia',
    #     'sc' => 'Seychelles',
    #     'sl' => 'Sierra Leona',
    #     'sg' => 'Singapur',
    #     'sy' => 'Siria',
    #     'so' => 'Somalia',
    #     'lk' => 'Sri Lanka',
    #     'za' => 'Sudáfrica',
    #     'sd' => 'Sudán',
    #     'ch' => 'Suiza',
    #     'sr' => 'Surinam',
    #     'sj' => 'Svalbard y Jan Mayen',
    #     'eh' => 'Sáhara Occidental',
    #     'th' => 'Tailandia',
    #     'tw' => 'Taiwán',
    #     'tz' => 'Tanzania',
    #     'tj' => 'Tayikistán',
    #     'io' => 'Territorio Británico del Océano Índico',
    #     'tf' => 'Territorios Australes Franceses',
    #     'ps' => 'Territorios Palestinos',
    #     'tl' => 'Timor-Leste',
    #     'tg' => 'Togo',
    #     'tk' => 'Tokelau',
    #     'to' => 'Tonga',
    #     'tt' => 'Trinidad y Tobago',
    #     'tm' => 'Turkmenistán',
    #     'tr' => 'Turquía',
    #     'tv' => 'Tuvalu',
    #     'tn' => 'Túnez',
    #     'ua' => 'Ucrania',
    #     'ug' => 'Uganda',
    #     'uy' => 'Uruguay',
    #     'uz' => 'Uzbekistán',
    #     'vu' => 'Vanuatu',
    #     've' => 'Venezuela',
    #     'vn' => 'Vietnam',
    #     'wf' => 'Wallis y Futuna',
    #     'ye' => 'Yemen',
    #     'dj' => 'Yibuti',
    #     'zm' => 'Zambia',
    #     'zw' => 'Zimbabue'
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
        if ! _checkUrl -l="https://download.prestashop.com/download/releases/${zipFile}"; then
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

    # chmod folders to 755 and files to 644
    find "${WEB_DIR}/${DOMAIN}/" -type d -exec chmod 0755 {} \;
    find "${WEB_DIR}/${DOMAIN}/" -type f -exec chmod 0644 {} \;

    # Add write permissions for config files
    find "${WEB_DIR}/${DOMAIN}/" -exec chown $WEB_USER:$WEB_USER {} \;
    local installDir="${WEB_DIR}/${DOMAIN}/install"
    php "${WEB_DIR}/${DOMAIN}/install/index_cli.php" "${INSTALL_ARGS}" && {
        _success "Prestashop installed successfully !"
        echo "You can access your Prestashop at http://${DOMAIN}/"
        echo "Admin panel: http://${DOMAIN}/admin"

    } || {
        _die "Prestashop installation failed !"
    }
    if [ -d $installDir ]; then
        _warning "Deleting existing $installDir"
        rm -rf $installDir || {
            _die "rm ${installDir} failed !"
        }
    fi
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
