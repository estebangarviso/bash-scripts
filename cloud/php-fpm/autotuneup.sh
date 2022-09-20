#!/bin/sh

# Creates a configuration script to run once final servers are up.
PROCESS_SIZE_APACHE_MB=3
PROCESS_SIZE_PHP_MB=8

# Get some values from the server
MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '"'"'{print $2}'"'"')
MEMORY_MB=$(($MEMORY_KB / 1024))
MEMORY_AVAILABLE_MB=$(($MEMORY_KB / 1178))
NUM_CORES=$(nproc --all)
echo "Memory: $MEMORY_MB MB"
echo "Memory Available: $MEMORY_AVAILABLE_MB MB"
echo "Num Cores $NUM_CORES"

#Now do some calculations
SERVER_LIMIT=$(($MEMORY_AVAILABLE_MB / $PROCESS_SIZE_APACHE_MB))
echo "HTTP MPM Server Limit: $SERVER_LIMIT"

#Convert Apache from mpm-prefork to mpm-worker
#Set params
#<IfModule mpm_*_module>
#  ServerLimit           (Total RAM - Memory used for Linux, DB, etc.) / process size
#   StartServers          (Number of Cores)
#   MinSpareThreads       25
#   MaxSpareThreads       75
#   ThreadLimit           64
#   ThreadsPerChild       25
#   MaxRequestWorkers     (Total RAM - Memory used for Linux, DB, etc.) / process  size
#   MaxConnectionsPerChild   1000
# </IfModule>
# /etc/httpd/conf.modules.d/00-mpm.conf

echo "
# LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
# LoadModule mpm_worker_module modules/mod_mpm_worker.so
LoadModule mpm_event_module modules/mod_mpm_event.so

<IfModule mpm_*_module>
  ServerLimit           $SERVER_LIMIT
  StartServers          $NUM_CORES
  MinSpareThreads       25
  MaxSpareThreads       75
  ThreadLimit           64
  ThreadsPerChild       25
  MaxRequestWorkers     $SERVER_LIMIT
  MaxConnectionsPerChild   1000
</IfModule>
" >/etc/httpd/conf.modules.d/00-mpm.conf

# Configure the workers
# pm = dynamic
# pm.max_children         (total RAM - (DB etc) / process size) = 850
# pm.start_servers        (cpu cores * 4)
# pm.min_spare_servers    (cpu cores * 2)
# pm.max_spare_servers    (cpu cores * 4)
# pm.max_requests         1000
MAX_CHILDREN=$(($MEMORY_AVAILABLE_MB / $PROCESS_SIZE_PHP_MB))
echo "Max Children: $MAX_CHILDREN"
NUM_START_SERVERS=$(($NUM_CORES * 4))
NUM_MIN_SPARE_SERVERS=$(($NUM_CORES * 2))
NUM_MAX_SPARE_SERVERS=$(($NUM_CORES * 4))

sed -c -i "s/^;*pm.max_children.*/pm.max_children = $MAX_CHILDREN/" /etc/php-fpm.d/www.conf
sed -c -i "s/^;*pm.start_servers.*/pm.start_servers = $NUM_START_SERVERS/" /etc/php-fpm.d/www.conf
sed -c -i "s/^;*pm.min_spare_servers.*/pm.min_spare_servers =  $NUM_MIN_SPARE_SERVERS/" /etc/php-fpm.d/www.conf
sed -c -i "s/^;*pm.max_spare_servers.*/pm.max_spare_servers =  $NUM_MAX_SPARE_SERVERS/" /etc/php-fpm.d/www.conf
sed -c -i "s/^;*pm.max_requests = 500.*/pm.max_requests = 1000/" /etc/php-fpm.d/www.conf
