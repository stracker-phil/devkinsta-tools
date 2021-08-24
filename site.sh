#!/bin/bash

# 
# Script to disable or enable a DevKinsta website
#
# When disabling a website, its docoot folder is moved to the /archive
# directory (outside the servers webroot folder) and a placeholder file
# is left in its place to keep the website settings in DevKinsta.
#
# When enabling a website again, that process is reversed.
#
# Todo: Take a DB snapshot while disabling the website and restore it again
# Todo: Update Tower sqlite DB and update repos inside the moved foled
#

# -----
root_dir=$(dirname $(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd))
usage() {
	echo; echo "Usage:"; echo
	echo "$0 enable|disable <website-dir>"; echo
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

state=$1
site=$2
pub_dir=$root_dir/public/$site
arch_dir=$root_dir/archive/$site
#db_done=$(docker exec devkinsta_fpm bash -c '[ ! -f /www/kinsta/mysql.conf ] || echo 1')


#if [ -z "$db_done" ]; then
#	error "Please first run the setup-backup.sh script"
#fi
if [ -z "$state" ] || [ -z "$site" ]; then
	usage
fi
if [ "enable" != $state ] && [ "disable" != $state ]; then
	usage
fi

if [ ! -d $pub_dir ]; then
	error "Could not find the website inside the 'public' folder:" "$pub_dir"
	exit 1
fi

#
# Disable site.
#
if [ "disable" = $state ]; then
	title "Archive $site"
	rm -rf $arch_dir
	mv $pub_dir $arch_dir
	mkdir -p $pub_dir
	cat > $pub_dir/index.html <<-EOF
	<!doctype html>
	<html>
	<body style="background:#fff">
	<div style="margin:50px auto;max-width:600px;font-size:20px;font-family:'Helvetica Neue','Open Sans',sans">
	<h1>This website was archived</h1>
	<p>Use following command to unarchive the website:</p>
	<pre><code>cd $root_dir/private<br>bash $0 enable $site</code></pre>
	</div>
	</body>
	</html>
EOF
	log "Done! Moved '$site' to the archive folder"
fi

#
# Enable site.
#
if [ "enable" = $state ]; then
	title "Restore $site"
	if [ ! -d $arch_dir ]; then
		error "Could not find an archived version of the website:" "$arch_dir"
	fi

	rm -rf $pub_dir
	mv $arch_dir $pub_dir
	log "Done! Restored '$site' from the archive folder"
fi
