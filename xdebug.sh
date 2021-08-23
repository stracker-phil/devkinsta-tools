#!/bin/bash

# docker exec devkinsta_fpm bash -c 'bash /www/kinsta/private/xdebug.sh on'
# docker exec devkinsta_fpm bash -c 'bash /www/kinsta/private/xdebug.sh off'

if [ "on" == "$1" ]; then
	state=on
else 
	state=off
fi

update-alternatives --list php | while read bin ; do
	version=${bin#"/usr/bin/php"}
	ini_path="/etc/php/$version/fpm/conf.d/20-xdebug.ini"
	service="/etc/init.d/php$version-fpm"

	if [ "on" == "$state" ]; then	
		echo "=== Enable Xdebug ==="; sed -ie 's/^; //' $ini_path
	else
		echo "=== Disable Xdebug ==="; sed -ie 's/^/; /' $ini_path
	fi 

 	echo "=== Restart $service ==="; $service restart
done

echo; echo "All done"