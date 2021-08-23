#!/bin/bash

# docker exec devkinsta_fpm bash -c 'bash /www/kinsta/private/setup-xdebug.sh'

echo "=== Updating apm ==="; apt-get update

# Get a list of all present PHP versions and setup Xdebug for them.
update-alternatives --list php | while read bin ; do
	version=${bin#"/usr/bin/php"}
	package="php$version-xdebug"
	ini_path="/etc/php/$version/fpm/conf.d/20-xdebug.ini"
	service="/etc/init.d/php$version-fpm"
	so_path=$(/usr/bin/php$version -r 'echo ini_get("extension_dir");')

	echo; echo "=== Installing $package ==="; apt-get -y install $package

	echo "=== Xdebug extension for php$version ==="; ls "$so_path/xdebug.so"
	
	echo "=== Prepare $ini_path ==="; cat > $ini_path <<-EOF
	zend_extension=xdebug.so
	xdebug.mode=develop,debug
	xdebug.client_port=9003
	xdebug.client_host=host.docker.internal
	xdebug.log=/www/kinsta/logs/xdebug.log
EOF

	echo "=== Restart $service ==="; $service restart
done

echo; echo "All done"