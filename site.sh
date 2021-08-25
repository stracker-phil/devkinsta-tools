#!/bin/bash

#
# Todo: Take a DB snapshot while disabling the website and restore it again
# Todo: Update Tower sqlite DB and update repos inside the moved foled
#

source "$(dirname $0)/.lib.sh"

state=$1
site=$2
pub_dir=$root_dir/public/$site
arch_dir=$root_dir/archive/$site
#db_done=$(docker exec devkinsta_fpm bash -c '[ ! -f /www/kinsta/mysql.conf ] || echo 1')

usage() {
	title "Usage"
	cmd "$0" "enable|disable <website-dir>"

	title "Description"
	echo "Script to disable or enable a DevKinsta website"
	echo ""
	echo "When disabling a website, its docoot folder is moved to the /archive"
	echo "directory (outside the servers webroot folder) and a placeholder file"
	echo "is left in its place to keep the website settings in DevKinsta."
	echo ""
	echo "When enabling a website again, that process is reversed."
	exit 1
}
if [ "--help" = "$1" ] || [ "-h" = "$1" ]; then 
	usage 
fi

# -----

site_enable() {
	title "Restore $site"
	if [ ! -d $arch_dir ]; then
		error "Could not find an archived version of the website:" "$arch_dir"
	fi

	rm -rf $pub_dir
	mv $arch_dir $pub_dir
	log "Done! Restored '$site' from the archive folder"
}

site_disable() {
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
}

# -----

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

if [ "disable" = $state ]; then
	site_disable
fi
if [ "enable" = $state ]; then
	site_enable
fi
