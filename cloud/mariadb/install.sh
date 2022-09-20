#!/bin/bash

# Contribution: Lewiscowles1986
# Reference: https://gist.github.com/Lewiscowles1986/973f4fa5f0a92f152cd5

source "$(pwd)/core/lib.sh"

# Sanity check
_checkRoot

function installLinux() {
    # Install expect
    apt install -qq expect -y
    # Install MariaDB
    apt-get install -qq mariadb-server mariadb-client -y
    # Start MariaDB
    sh <$(systemctl start mariadb || service mysql start) >/dev/null 2>&1
    # Secure MariaDB
    echo "$_secureMariaDB"
    # Restart MariaDB
    sh <$(systemctl restart mariadb || service mysql restart) >/dev/null 2>&1
    # Purge expect
    apt-get purge -qq expect -y
}

function installMac() {
    # Install expect
    brew install expect
    # Install MariaDB
    if ! brew ls --versions mariadb >/dev/null; then
        brew install mariadb
    fi
    # Start MariaDB
    brew services start mariadb
    # Restart MariaDB
    brew services restart mariadb
    # Secure MariaDB
    echo "$_secureMariaDB"
    # Purge expect
    brew uninstall expect
}

_secureMariaDB=$(expect -c "
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

export MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16)

function main() {
    _header "Installing MariaDB"
    if [[ "$OSTYPE" == "linux"* ]]; then
        installLinux
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        installMac
    else
        _warning "OS not supported"
    fi
    _success "MariaDB installed"
}

main
