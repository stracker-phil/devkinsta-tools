# Helper library used by other scripts in this repo/folder.

root_dir=$(dirname $(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd))

# Test, if color output is supported.
color=0
if tput Co > /dev/null 2>&1
then
    test "`tput Co`" -gt 2 && color=1
elif tput colors > /dev/null 2>&1
then
    test "`tput colors`" -gt 2 && color=1
fi

# ----

run_in_docker() {
	local cmd=$1
	shift
	if [ ! -f /.dockerenv ]; then
		docker exec devkinsta_fpm bash -c "bash /www/kinsta/private/$cmd $*"
		exit 0
	fi
}

title() {
	echo
	if [ 0 = $color ]; then
		echo "=== $1 ===";
	else
		echo "$(tput setaf 3)=== $(tput bold)$1$(tput sgr0)$(tput setaf 3) ===$(tput sgr0)";
	fi
}

log() {
	if [ 0 = $color ]; then
		echo " * $*"
	else
		echo "$(tput setaf 6) * $(tput sgr0)$*"
	fi
}

cmd() {
	local cmd=$1
	shift
	if [ 0 = $color ]; then
		echo " \$ $cmd $*"
	else 
		echo "$(tput setaf 6) \$$(tput sgr0) $(tput setaf 4)$cmd $(tput bold)$*$(tput sgr0)"
	fi
}

error() {
	local msg=$1
	shift
	echo

	if [ 0 = $color ]; then
		echo "ERROR! $msg";
	else
		echo "$(tput setaf 1)$(tput bold)ERROR!$(tput sgr0) $(tput setaf 1)$msg$(tput sgr0)";
	fi

	if [ -n "$1" ]; then
		echo $*; 
	fi
	exit 1
}