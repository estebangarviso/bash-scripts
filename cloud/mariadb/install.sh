#!/bin/bash

# Contribution: Lewiscowles1986
# Reference: https://gist.github.com/Lewiscowles1986/973f4fa5f0a92f152cd5

# source "../../core/lib.sh"
wget -qO- https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/core/lib.sh | bash

# Sanity check
_checkRoot

function installLinux() {
    apt install -qq expect

    # MariaDB 10.3
    # Check if MariaDB is installed
    if ! dpkg -s mariadb-server >/dev/null 2>&1; then
        apt-get install -qq mariadb-server
    fi
    if ! dpkg -s mariadb-client >/dev/null 2>&1; then
        apt-get install -qq mariadb-client
    fi

    _secureMariaDB=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"root\r\"
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

    echo "$_secureMariaDB"

    apt-get purge -qq expect
}

function installMac() {
    # Check if MariaDB is installed
    if ! brew ls --versions mariadb >/dev/null; then
        brew install mariadb
    fi
}

export MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16)

function main() {
    _header "Installing MariaDB"
    if [[ "$OSTYPE" == "linux"* ]]; then
        installLinux
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        installMac
    else
        # _die "OS not supported"
    fi
    _success "MariaDB installed"
}

main
