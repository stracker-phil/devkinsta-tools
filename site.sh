#!/bin/bash

state=$1
site=$2
root_dir=$(dirname $(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd))
pub_dir=$root_dir/public/$site
arch_dir=$root_dir/archive/$site
#db_done=$(docker exec devkinsta_fpm bash -c '[ ! -f /www/kinsta/mysql.conf ] || echo 1')

usage() {
	echo; echo "Usage:"; echo
	echo "$0 enable|disable <website-dir>"; echo
	exit 1
}
#install_note() {
#	echo; echo "Installation:"; echo
#	echo "Please first run the setup-backup script."
#	exit 1
#}
error() {
	local msg=$1
	shift
	echo; echo "ERROR: $msg";
	if [ $1 ]; then
		echo $*
	fi
	echo
	exit 1
}

#if [ -z "$db_done" ]; then
#	install_note
#fi
if [ "enable" != "$state" ] && [ "disable" != "$state" ]; then
	usage
fi
if [ -z "$state" ] || [ -z "$site" ]; then
	usage
fi

if [ ! -d $pub_dir ]; then
	error "Could not find the website inside the 'public' folder:" "$pub_dir"
	exit 1
fi

if [ "enable" = $state ]; then
	if [ ! -d $arch_dir ]; then
		error "Could not find an archived version of the website:" "$arch_dir"
	fi

	rm -rf $pub_dir
	mv $arch_dir $pub_dir
	echo "Done! Restored '$site' from the archive folder"
fi

if [ "disable" = $state ]; then
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
	echo "Done! Moved '$site' to the archive folder"
fi