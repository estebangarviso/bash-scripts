# Bash scripts shortcuts

This repository contains a collection of bash scripts to automatize some tasks.
Be sure to have the `bash` shell installed on your system and run the code as root.
Read usage methods in the scripts in order to know how to use them.
Files are named as `bash-scripts/main/<service>/<action>.sh`.

_Scripts tested on Ubuntu 22.04 LTS._

## Scripts for Cloud Services

### MariaDB

```bash
wget -O - https://raw.githubusercontent.com/estebangarviso/bash-scripts/master/cloud/mariadb/install.sh | bash
wget -O - https://raw.githubusercontent.com/estebangarviso/bash-scripts/master/cloud/mariadb/create-database.sh | bash -db=database_name
```

### Mail Server

```bash
wget -O - https://raw.githubusercontent.com/estebangarviso/bash-scripts/master/cloud/mail-server/install.sh | bash
```

### CMS

```bash
wget -O - https://raw.githubusercontent.com/estebangarviso/bash-scripts/master/cloud/cms/install.sh | bash
```

### PHP-FPM

```bash
wget -O - https://raw.githubusercontent.com/estebangarviso/bash-scripts/master/cloud/php-fpm/install.sh | bash
```
