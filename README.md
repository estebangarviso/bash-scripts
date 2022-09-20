# Bash scripts shortcuts

This repository contains a collection of bash scripts to automatize some tasks.
Be sure to have the `bash` shell installed on your system and run the code as root.
Read usage methods in the scripts in order to know how to use them.
Files are named as `bash-scripts/main/<service>/<action>.sh`.

_Scripts tested on Ubuntu 22.04 LTS._

## Scripts for Cloud Services

Before using the scripts, you need to clone or download the repository with the next commands:

```bash
git clone https://github.com/estebangarviso/bash-scripts.git
cd bash-scripts
```

or

```bash
cd ~/ && sh <(curl https://github.com/estebangarviso/bash-scripts/archive/main.zip || wget https://github.com/estebangarviso/bash-scripts/archive/main.zip) && apt install unzip && unzip main.zip && rm main.zip && chmod u+x bash-scripts-main/*.sh && cd bash-scripts-main
```

### MariaDB

```bash
cloud/mariadb/install.sh
```

```bash
cloud/mariadb/create-database.sh -db=database_name
```

### Mail Server

```bash
cloud/mail-server/install.sh
```

### CMS

```bash
cloud/cms/install.sh
```

### PHP-FPM

```bash
cloud/php-fpm/install.sh
```

### Rclone (Coming soon)

```bash
cloud/rclone/install.sh
```
