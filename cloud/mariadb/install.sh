#!/bin/sh

# Contribution: Lewiscowles1986
# Reference: https://gist.github.com/Lewiscowles1986/973f4fa5f0a92f152cd5

source "$(pwd)/core/lib.sh"

# Sanity check
_checkSanity

function _secureMariaDB() {
    echo $(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"\r\"
expect \"Switch to unix_socket authentication \[Y/n\]\"
send \"n\r\"
expect \"Change the root password?\"
send \"y\r\"
expect \"New password:\"
send \"${MYSQL_ROOT_PASSWORD}\r\"
expect \"Re-enter new password:\"
send \"${MYSQL_ROOT_PASSWORD}\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
}

function _isSecureMariaDB() {
    local result=$(mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SELECT 1" 2>&1)
    if [[ "$result" == *"ERROR"* ]]; then
        return 1
    else
        return 0
    fi
}

function installOnLinux() {
    # Install expect
    apt install -qq expect -y
    # Install MariaDB
    if ! _isInstalled "mariadb-server"; then
        _info "Installing MariaDB Server"
        apt install -qq mariadb-server -y
    else
        _info "MariaDB Server is already installed"
    fi
    if ! _isInstalled "mariadb-client"; then
        _info "Installing MariaDB Client"
        apt install -qq mariadb-client -y
    else
        _info "MariaDB Client is already installed"
    fi
    # Start MariaDB (it is required to secure it)
    _startService mariadb
    # Secure MariaDB
    _secureMariaDB
    # Restart MariaDB
    _restartService mariadb
    # Purge expect
    apt-get purge -qq expect -y
}

function installOnMac() {
    # Install expect
    brew install expect
    # Install MariaDB
    if _isInstalled "mariadb"; then
        brew install mariadb
    fi
    # Start MariaDB (it is required to secure it)
    _startService mariadb
    # Secure MariaDB
    _secureMariaDB
    # Restart MariaDB
    _restartService mariadb
    # Purge expect
    brew uninstall expect
}

export MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16)

function main() {
    _header "Installing MariaDB"
    if [[ "$OSTYPE" == "linux"* ]]; then
        installOnLinux
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        installOnMac
    else
        _warning "OS not supported"
    fi
    if _isSecureMariaDB; then
        _success "MariaDB is secure"
    else
        _error "MariaDB is not secure, please try to secure it manually and start the service"
        # Stop MariaDB
        _stopService mariadb
    fi
    _success "MariaDB installed"
}

main
