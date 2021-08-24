#!/bin/bash

#
# Installation:
# > wp-cron.sh <site> <state>
#
# Activates or deactivates the cron daemon and schedules a czustom
# wp-cron.php interval.
#

source "$(dirname $0)/.lib.sh"

site_dir=$1
interval=$2
pub_dir=$root_dir/public/$site_dir/
site_script=/www/kinsta/wp-cron-$site_dir.sh

usage() {
	title "Usage"
	cmd "$0" "<website-dir> <interval>'"
	echo "- website-dir ... The root dir of the site, inside the public folder"
	echo "- interval ... Cron interval (in minutes). Set to 0 to disable wp-cron"
	echo; echo "Call wp-cron in 5-minute intervals:"
	cmd "$0" "my_site 5'"
	echo "Disable wp-cron for website.local:"
	cmd "$0" "my_site 0'"
	exit 1
}

if [ -z "$site_dir" ] || [ -z "$interval" ]; then
	usage
fi

if [ ! -d "$pub_dir" ]; then
	error "Could not find the website inside the 'public' folder:" "$pub_dir"
fi

# Propagate the command to docker, if called on the host.
run_in_docker $0 $*

if ! command -v cron &> /dev/null; then
	title "Installing cron"
	apt-get update; apt-get install cron
	log "OK"
fi

title "Add cron to autostart"
init_file=/etc/supervisor/conf.d/supervisord.conf
if ! grep -q program:cron $init_file; then
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
fi
update-rc.d cron defaults
log "OK"

log_file=/www/kinsta/logs/cron.log
title "Setup cron-job"
log "Website: $site_dir"
log "Path: $pub_dir"

cat >$site_script<<-EOF
#!/bin/bash

adddate() {
	while IFS= read -r line; do
		printf '%s | %s\n' "\$(date "+%Y-%m-%d %H:%M:%S")" "\$line";
	done
}

cd $pub_dir
wp cron event run --due-now --allow-root | adddate >> $log_file 2>&1
EOF

crontab -l > new_cron
sed -i "\=$site_script=d" new_cron

if [ "0" != $interval ]; then
	echo "*/$interval * * * * bash $site_script" >> new_cron
	log "Interval: $interval"
else
	log "Disabled wp-cron"
fi

crontab new_cron
rm new_cron
service cron start &>/dev/null
log "OK"