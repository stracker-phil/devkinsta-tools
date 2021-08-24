#!/bin/bash

#
# Usage:
# > setup-xdebug.sh
#
# Installs and configures the PHP Xdebug module.
#

source "$(dirname $0)/.lib.sh"

# Propagate the command to docker, if called on the host.
run_in_docker $0 $*

title "Updating apm"; apt-get update

# Get a list of all present PHP versions and setup Xdebug for them.
update-alternatives --list php | while read bin ; do
	version=${bin#"/usr/bin/php"}
	package="php$version-xdebug"
	ini_path="/etc/php/$version/mods-available/20-xdebug.ini"
	service="/etc/init.d/php$version-fpm"
	so_path=$(/usr/bin/php$version -r 'echo ini_get("extension_dir");')

	title "Installing $package"; apt-get -y install $package

	title "Xdebug extension for php$version"; ls "$so_path/xdebug.so"
	
	title "Prepare $ini_path"; cat > $ini_path <<-EOF
	zend_extension=xdebug.so
	xdebug.mode=develop,debug
	xdebug.client_port=9003
	xdebug.start_with_request=yes
	xdebug.client_host=host.docker.internal
	xdebug.log=/www/kinsta/logs/xdebug.log
EOF

	phpenmod xdebug
	title "Restart $service"; $service restart
done

echo; echo "All done"