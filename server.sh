#!/bin/bash

#
# Switch the webserver between DevKinsta (nginx) and MAMP Pro (Apache)
#
# Usage: server.sh kinsta|mamp
#
# Preparation:
#
# In MAMP Pro Settings, activate the following two options:
#    - Launch Group Start Servers: When starting MAMP PRO
#    - Stop Servers: when quitting MAMP PRO
# MAMP Pro Ports:
#    - Apache: 80 / 443
#    - MySQL:  8889
#
# 1. Create the website in DevKinsta
# 2. Start MAMP Pro and create a new (empty) host that points to the
#    DevKinsta/public/website folder.
#
# Attention: This script updates the DB_HOST of all wp-config.php 
# files inside the DevKinsta/public folder!
#

web_server=$1
db_server=$2

# -----
root_dir=$(dirname $(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd))
usage() {
	echo; echo "Usage:"
	echo "> $0 [<webserver> [<dbserver>]]"
	echo "  The default value for both servers is 'kinsta'"
	echo; echo "Samples:"
	echo "> $0 kinsta        # Nginx and MySQL on Docker"
	echo "> $0 kinsta mamp   # Nginx on Docker, MySQL on MAMP"; echo
	exit 1
}
title() {
	echo; echo "=== $1 ===";
}
log() {
	echo " * $1"
}
error() {
	local msg=$1
	shift; echo; echo "ERROR: $msg";
	if [ $1 ]; then echo $*; fi; echo
	exit 1
}
# -----

stop_kinsta() {
	log "Stopping DevKinsta web servers ..."
	docker stop devkinsta_nginx devkinsta_fpm
}
start_kinsta() {
	log "Starting DevKinsta web servers ..."
	res=$(docker start devkinsta_fpm devkinsta_nginx)

	echo "$res"; echo

	cat <<EOF | docker exec --interactive devkinsta_fpm bash 
	update-alternatives --list php | while read bin ; do
		version=\${bin#"/usr/bin/php"}
		service="/etc/init.d/php\$version-fpm"
		\$service restart
	done
EOF
	
	if ! grep -q devkinsta_nginx <<<"$res"; then
		title "Could not start nginx!"
		echo "  Usually, this happens because Apache is still running."
		echo "  Very likely, Apache is currently shutting down, so you can"
		echo "  wait a minute and try again."
		echo; echo "  If this does not help, try the following command:"
		echo "  > lsof -i -P | grep -E ':(80|443).*LISTEN' # show running servers"
		echo "  > sudo killall httpd                       # kill the httpd server"
	fi
}

stop_mamp() {
	log "Stopping MAMP web servers ..."
	osascript -e 'quit app "MAMP PRO"'
}
start_mamp() {
	log "Starting MAMP web servers ..."
	open --hide /Applications/MAMP\ Pro.app
}

set_host() {
	local host=$1
	title "Change DB_HOST in wp-config files"

	for f in $(find $root_dir/public -maxdepth 2 -type f -name "wp-config.php"); do
		short=${f#$root_dir/public/}
		log "Update $short"
		sed -Ei '' "s/(define\([[:space:]]*'DB_HOST',[[:space:]]*')(.*)('[[:space:]]*\);).*$/\1$host\3 # Previous: \2/g" "$f"
	done
}

if [ ! -d /Applications/MAMP\ Pro.app ]; then
	error "MAMP Pro not found"
fi
if [ -z "$web_server" ]; then
	web_server=kinsta
fi
if [ -z "$db_server" ]; then
	db_server=kinsta
fi
if [ "kinsta" != $web_server ] && [ "mamp" != $web_server ]; then
	usage
fi
if [ "kinsta" != $db_server ] && [ "mamp" != $db_server ]; then
	usage
fi

title "Switch servers"

if [ "kinsta" = $web_server ]; then
	log "Web Server: DevKinsta"
else 
	log "Web Server: MAMP Pro"
fi
if [ "kinsta" = $db_server ]; then
	log "DB Server:  DevKinsta"
else 
	log "DB Server:  MAMP Pro"
fi

title "Stopping servers"
stop_mamp
stop_kinsta

sleep 1

if [ "kinsta" = $web_server ]; then
	if [ "kinsta" = $db_server ]; then
		set_host "devkinsta_db"
	else 
		set_host "host.docker.internal:8889"
	fi
	title "Start DevKinsta Server"
	start_kinsta
fi

if [ "mamp" = $web_server ]; then
	if [ "kinsta" = $db_server ]; then
		set_host "127.0.0.1:15100"
	else 
		set_host "localhost:8889"
	fi
	title "Start MAMP Pro Server"
	start_mamp
fi