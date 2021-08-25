#!/bin/bash

source "$(dirname $0)/.lib.sh"

usage() {
	title "Usage"
	cmd "$0" "on"
	cmd "$0" "off"

	title "Description"
	echo "Disables or enabled the Xdebug module for PHP."
	echo "Xdebug often decreases performance considerably. That's why it's"
	echo "best to disable it when it's not needed"
	echo; echo "You need to call 'setup-xdebug.sh' once before using this script."
	exit 1
}
show_help $1

if [ -z "$1" ]; then
	usage
fi

# Propagate the command to docker, if called on the host.
run_in_docker $0 $*

if [ "on" == "$1" ] || [ "enable" == "$1" ]; then
	state=on
else
	state=off
fi

if [ "on" == "$state" ]; then	
	title "Enable Xdebug"
	phpenmod xdebug
else
	title "Disable Xdebug"
	phpdismod xdebug
fi
log "OK"

# Restart all php instances.
update-alternatives --list php | while read bin ; do
	version=${bin#"/usr/bin/php"}
	service="/etc/init.d/php$version-fpm"
	title "Restart $service"; $service restart
done

log "All done"