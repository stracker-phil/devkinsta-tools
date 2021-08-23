#!/bin/bash

# Installation:
# > docker exec devkinsta_fpm bash -c 'bash /www/kinsta/private/setup-backups.sh'

# Run backups manually:
# > docker exec devkinsta_fpm bash -c 'bash /www/kinsta/run-backups.sh'

# This script creates a DB dump of all databases in an 3-hour interval
# DB backups are stored in the folder DevKinsta/private/backups
#
# Note: Before taking a new backup of a DB, the previous backups of 
# that database are deleted. You will only have the most current 
# backup of each database. Make sure to include the backups folder in
# Timemachine and Backblaze backups!

if ! command -v cron &> /dev/null; then
  echo "=== Installing cron ===";
  apt-get update; apt-get install cron
  echo "OK"
fi

init_file=/etc/supervisor/conf.d/supervisord.conf
if [ -z grep program:cron $init_file ]; then
  echo; echo "=== Add cron to autostart ===";
  # This container uses supervisor instead of rc.
  cat > $init_file <<-EOF
  [program:cron]
  command = cron
  autostart=true
  autorestart=true
  priority=5
  stdout_logfile=/var/log/cron.log
  stdout_logfile_maxbytes=0
  stderr_logfile=/var/log/cron-error.log
  stderr_logfile_maxbytes=0
EOF
  echo "OK"
fi

echo; echo "=== Prepare backup folder ===";
target=/www/kinsta/private/backups/
mkdir -p "$target"
echo "OK"

conf_file=/www/kinsta/mysql.conf
command=/www/kinsta/run-backup.sh
log_file=/www/kinsta/logs/cron.log

echo; echo "=== Create $conf_file ===";
for f in $(find /www/kinsta/public -maxdepth 2 -type f -name "wp-config.php"); do
  db_user=$(grep "DB_USER" $f | cut -d "," -f2 | cut -d "'" -f2)
  db_password=$(grep "DB_PASSWORD" $f | cut -d "," -f2 | cut -d "'" -f2)
  db_host=$(grep "DB_HOST" $f | cut -d "," -f2 | cut -d "'" -f2)
  if [ -n "$db_password" ] && [ -n "$db_user" ] && [ -n "$db_host" ]; then
    break
  fi
done
cat > $conf_file <<-EOF
[client]
user=$db_user
password=$db_password
host=$db_host
EOF
echo "OK"

echo; echo "=== Create backup script ===";
cat > $command <<-EOF
echo "Starting automated DB backups"
list=\$(mysql --defaults-extra-file=$conf_file -Bse "SHOW DATABASES;")

for db in \${list[@]}; do
  if \
    [ "\$db" == "mysql" ] \
    || [ "\$db" == "sys" ] \
    || [ "\$db" == "performance_schema" ] \
    || [ "\$db" == "information_schema" ]
  then
    continue
  fi

  tstamp=\$(date "+%Y%m%d.%H%M")

  echo "Backup of \$db @ \$tstamp ..."
  rm -f "$target"\$db.*sql
  mysqldump --defaults-extra-file=$conf_file --column-statistics=0 \$db > "$target"\$db.\$tstamp.sql
done
echo "Backup complete!"; echo ""
EOF
echo "OK"

echo; echo "=== Setup cron-job ===";
crontab -l > new_cron
sed -i "\=$command=d" new_cron
echo "0 1,4,7,10,13,16,19,22 * * * bash $command >> $log_file 2>&1" >> new_cron
crontab new_cron
rm new_cron
service cron start
echo "OK"

# Just to be sure:
echo; service cron status