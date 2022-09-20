# Bash scripts shortcuts

This repository contains a collection of bash scripts to automatize some tasks.
Be sure to have the `bash` shell installed on your system and run the code as root.
For linux users, `curl` will be installed automatically.
Read usage methods in the scripts in order to know how to use them.
Files are named as `bash-scripts/main/<service>/<action>.sh`.

_Scripts tested on Ubuntu 22.04 LTS._

## Scripts for Cloud Services

### MariaDB

#### Install

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/cloud/mariadb/install.sh)"
```

#### Create database

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/cloud/mariadb/create-database.sh) | bash -db=<database_name>"
```

### Mail Server

#### Install

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/cloud/mail-server/install.sh)"
```

### CMS

#### Install

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/cloud/cms/install.sh)"
```

### PHP-FPM

#### Install

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/cloud/php-fpm/install.sh)"
```

### Rclone (Coming soon)

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/estebangarviso/bash-scripts/main/cloud/rclone/install.sh)"
```
