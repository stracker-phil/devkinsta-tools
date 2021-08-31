#!/bin/bash

source .lib.sh

web_server=$1
db_server=$2

usage() {
	title "Usage"
	cmd "$0" "--info"
	cmd "$0" "<web-server> <db-server>"
	log "<web-server> .. 'kinsta' or 'mamp'. Default is 'kinsta'"
	log "<db-server> .. 'kinsta' or 'mamp'. Default is 'kinsta'"
	
	title "Samples"
	echo "Use Nginx and MySQL on Docker:"
	cmd "$0" "kinsta"
	echo "Use Nginx on Docker, MySQL on MAMP:"
	cmd "$0" "kinsta mamp"

	title "Description"
	echo " Switch the webserver between DevKinsta (nginx) and MAMP Pro (Apache)"

	title "Preparation:"
	echo "In MAMP Pro Settings, activate the following two options:"
	echo "   - Launch Group Start Servers: When starting MAMP PRO"
	echo "   - Stop Servers: when quitting MAMP PRO"
	echo "MAMP Pro Ports:"
	echo "   - Apache: 80 / 443"
	echo "   - MySQL: 8889"
	echo ""
	echo "1. Create the website in DevKinsta"
	echo "2. Start MAMP Pro and create a new (empty) host that points to the"
	echo "   DevKinsta/public/website folder."
	
	title "Attention"
	echo "This script updates the DB_HOST of all wp-config.php files"
	echo "inside the DevKinsta/public folder!"
	exit 1
}
show_help $1

show_info() {
	title "Server Info"
	log "Web server ...... $DEVKINSTA_WEB_SERVER"
	log "MySQL server .... $DEVKINSTA_DB_SERVER"
	log "MySQL host ...... $DEVKINSTA_DB_HOST"
	exit 1
}
if [ "--info" = "$1" ] || [ "-i" = "$1" ]; then
	show_info
fi

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

# -----

stop_mamp() {
	log "Stopping MAMP web servers ..."
	osascript -e 'quit app "MAMP PRO"'
}
start_mamp() {
	log "Starting MAMP web servers ..."
	open --hide /Applications/MAMP\ Pro.app
}

# -----

set_host() {
	local host=$1
	title "Change DB_HOST in wp-config files"

	for f in $(find $root_dir/public -maxdepth 2 -type f -name "wp-config.php"); do
		short=${f#$root_dir/public/}
		log "Update $short"
		sed -Ei '' "s/(define\([[:space:]]*'DB_HOST',[[:space:]]*')(.*)('[[:space:]]*\);).*$/\1$host\3 # Previous: \2/g" "$f"
	done
}

# -----

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
	export DEVKINSTA_DB_SERVER=kinsta
else 
	log "DB Server:  MAMP Pro"
	export DEVKINSTA_DB_SERVER=mamp
fi

title "Stopping servers"
stop_mamp
stop_kinsta

# Briefly wait for servers to shutdown.
sleep 3

if [ "kinsta" = $web_server ]; then
	start_kinsta
	export DEVKINSTA_WEB_SERVER=kinsta

	if [ "kinsta" = $db_server ]; then
		export DEVKINSTA_DB_HOST=devkinsta_db
	else 
		export DEVKINSTA_DB_HOST=host.docker.internal:8889
		start_mamp
	fi
fi

if [ "mamp" = $web_server ]; then
	start_mamp
	export DEVKINSTA_WEB_SERVER=mamp

	if [ "kinsta" = $db_server ]; then
		export DEVKINSTA_DB_HOST=127.0.0.1:15100
	else 
		export DEVKINSTA_DB_HOST=localhost:8889
	fi
fi

set_host "$DEVKINSTA_DB_HOST"

set_config "DEVKINSTA_WEB_SERVER"
set_config "DEVKINSTA_DB_SERVER"
set_config "DEVKINSTA_DB_HOST"
