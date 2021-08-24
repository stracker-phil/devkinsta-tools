#!/bin/bash

#
# Disables or enabled the Xdebug module for PHP.
# Xdebug often decreases performance considerably. That's why it's best 
# to disable it when it's not needed
#

source "$(dirname $0)/.lib.sh"

usage() {
	title "Usage"
	cmd "$0" "on"
	cmd "$0" "off"
	exit 1
}

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

log "All done"