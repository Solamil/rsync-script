#!/bin/sh
#
# BEGIN CUSTOMIZABLE SCRIPT VARIABLES 
#

RSYNC="rsync"
RSYNC_DEFAULT_OPTS=( --human-readable --progress )
RSYNC_REMOTE_SHELL=( -e ssh )
RSYNC_COMPRESSION=( --compress --compress-choice=zstd --compress-level=22 )
# RSYNC_OPTS=( --recursive --times --update --verbose  ) # not in use
RSYNC_CONF_DIR="$XDG_CONFIG_HOME/rsync"
GLOBAL_FILTER="$RSYNC_CONF_DIR/global-filter"
TMP_DIR="/tmp"
RSYNC_GLOBAL_FILTER=( --filter="merge $GLOBAL_FILTER" )
HOST_REMOTE_LIST=( michael@lenovo michael@desktop )

#
# END CUSTOMIZABLE SCRIPT VARIABLES 
#

#
# BEGIN platform definable
#
die(){
	echo "$@" >&2
	exit 1
}
#
# END platform definable
#

#
# BEGIN rsync functions
#

rsync_alone(){
	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" \
	-rtvcpRE \
	"$@"
}

rsync_individual(){
	local src=$1; shift; local dst=$1; shift; local args="$@"
#	PUSH without /
	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -tvupE $args \
	$src $dst
	
}

rsync_media(){
	local src=$1; shift; local dst=$1; shift; local args="$@"

	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -rtvpR --ignore-existing $args \
	"${RSYNC_GLOBAL_FILTER[@]}" \
	$src/./{Movies/,Music/,docs/,Phone/} \
	$dst/

# 	"$RSYNC_GLOBAL_FILTER" 
#	--ignore-existing \
}

rsync_etc(){
	local src=$1; shift; local dst=$1; shift; local args="$@"

	sudo $RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -rtvupRE --links $args \
	$src/./{sudoers,locale.gen,locale.conf,pacman.d/hooks/} \
	$src/./ssh/sshd_config \
	$dst/
#	/etc/pulse/default.pa \
}

rsync_dirs(){
	local src=$1; shift; local dst=$1; shift; local args="$@"
#	--backup-dir="/tmp/" \
	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -rtvupRE --links $args --info=NAME1 -F \
	$src/./{dl/,docs/,scripts/,pics/,devel/} \
	$dst/

#	-F \
#	--delete-after "$RSYNC_GLOBAL_FILTER" \
}

rsync_files(){
	local src=$1; shift; local dst=$1; shift; local args="$@"

	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -rtvupRE --links $args --info=NAME1 -F \
	$src/./{.bitmonero/,.imwheelrc} \
	$src/./{.config/,scripts/,.local/share/} \
	$dst/
}

#	$src/./ \


#
# END rsync functions
#
#
# BEGIN sync functions
#

sync_remote_individual(){
#		pull) shift; rsync_individual "$remote_dest:$(pwd)/$1/" "$(pwd)/" "$@" ;;
	case "$1" in
		pull) shift; { echo "$1" | grep -q "^/"; } && src="$1" || src="$(pwd)/$1"; shift
				rsync_individual "$remote_dest:$src" "$src" "$@" ;;

		push) shift; { echo "$1" | grep -q "^/"; } && src="$1" || src="$(pwd)/$1"; shift
				rsync_individual "$src" "$remote_dest:$src" "$@" ;;

		diff) shift; { echo "$1" | grep -q "^/"; } && src="$1" || src="$(pwd)/$1"; shift
				rsync_individual "$remote_dest:$src" "$TMP_DIR$src" "--mkpath $@"
				diff -s -u "$src" "$TMP_DIR$src" ;;

		ls) shift; { echo "$1" | grep -q "^/"; } && src="$1" || src="$(pwd)/$1"; shift
				rsync_individual "$remote_dest:$src" "" "$@" ;;
		*) die "Usage: $PROGRAM $COMMAND files|dirs|media|etc|[pull|push|ls|diff FILE|DIR] [RSYNCOPTIONS] "  ;;
	esac
}

sync_remote_etc(){
	case "$1" in
		pull) shift; rsync_etc "$remote_dest:/etc" "/etc" "$@" ;; 
		push) shift; rsync_etc "/etc" "$remote_dest:/etc" "$@" ;;
		*) die "Usage: $PROGRAM $COMMAND etc pull|push [RSYNCOPTIONS]"  ;;
	esac
}

sync_remote_files(){
	case "$1" in
		pull) shift; rsync_files "$remote_dest:$HOME" "$HOME" "$@" ;;
		push) shift; rsync_files "$HOME" "$remote_dest:$HOME" "$@" ;;
		*) die "Usage: $PROGRAM $COMMAND files pull|push [RSYNCOPTIONS]"  ;;
	esac
}

sync_remote_dirs(){
	case "$1" in
		pull) shift; rsync_dirs "$remote_dest:$HOME" "$HOME" "$@" ;; 
		push) shift; rsync_dirs "$HOME" "$remote_dest:$HOME" "$@" ;;
		*) die "Usage: $PROGRAM $COMMAND dirs pull|push [RSYNCOPTIONS]"  ;;
	esac
}

sync_remote_media(){
	case "$1" in
		pull) shift; rsync_media "$remote_dest:/media/$user/HardDrive" "/media/$user/HardDrive" "$@" ;;
		push) shift; rsync_media "/media/$user/HardDrive" "$remote_dest:/media/$user/HardDrive" "$@" ;; # Syncing it back
		*) die "Usage: $PROGRAM $COMMAND media pull|push [RSYNCOPTIONS]"  ;;
	esac
}

sync_portable_media(){
	case "$1" in
		pull) shift; rsync_media "/media/$user/ExtDrive" "/media/$user/HardDrive" "$@" ;;
		push) shift; rsync_media "/media/$user/HardDrive" "/media/$user/ExtDrive" "$@" ;;
		*) die "Usage: $PROGRAM $COMMAND media pull|push [RSYNCOPTIONS]"  ;;
	esac
}

sync_portable_files(){
	case "$1" in
		pull) shift; rsync_files "$HOME/flashdrive/portable-home$HOME" "$HOME" "$@" ;;
		push) shift; rsync_files "$HOME" "$HOME/flashdrive/portable-home$HOME" "$@" ;;
		*) die "Usage: $PROGRAM $COMMAND files pull|push [RSYNCOPTIONS]"  ;;
	esac
}

sync_local_files(){
	case "$1" in
		pull) shift; rsync_files "$HOME/data/portable-home/$host$HOME" "$HOME" "$@" ;;
		push) shift; rsync_files "$HOME" "$HOME/data/portable-home/$host$HOME" "$@" ;;
		*) die "Usage: $PROGRAM $COMMAND files pull|push [RSYNCOPTIONS]"  ;;
	esac
}

#
# END sync functions
#

#
# END platform definable
#

#
# BEGIN subcommand function
# 
cmd_version(){
	cat <<-_EOF
	 --------------------------------------------------------------------
	| 				rs				     |
	|								     |
	|    rsync shell script for easier transfer files and directories    |
	|								     |
	| 			   version: v0.1			     |
	|								     |
	|			      Michal				     |
	 --------------------------------------------------------------------
	_EOF
}
cmd_usage(){
	cmd_version
	echo
	cat <<-_EOF
	Usage: 	$PROGRAM remote|USER@HOST files|dirs|media|etc pull|push [RSYNCOPTIONS]
	                Transfer what is defined in rsync_[files|dirs|media|etc]() functions.
	        $PROGRAM remote|USER@HOST pull|push FILE|DIR [RSYNCOPTIONS]
	        	Transfer FILE or DIR. 
	        $PROGRAM remote|USER@HOST ls DIR [RSYNCOPTIONS]
	        	List directory contents on remote host.
	        $PROGRAM remote|USER@HOST diff FILE [RSYNCOPTIONS]
	        	Compare local and remote FILE.	
	        $PROGRAM local media push|pull [RSYNCOPTIONS]
	        	Transfer what is defined in rsync_media() function locally.
	        $PROGRAM help
	        	Show this help text.
	        $PROGRAM version
	        	Show version information.

	_EOF
}

remote_catalog(){
	case "$1" in
		media) shift; sync_remote_media "$@" 			     "${RSYNC_REMOTE_SHELL[@]}" ;;
		dirs) shift; sync_remote_dirs "$@" "${RSYNC_COMPRESSION[@]}" "${RSYNC_REMOTE_SHELL[@]}" ;;
		files) shift; sync_remote_files "$@" "${RSYNC_COMPRESSION[@]}" "${RSYNC_REMOTE_SHELL[@]}" ;;
		etc) shift; sync_remote_etc "$@" "${RSYNC_COMPRESSION[@]}" "${RSYNC_REMOTE_SHELL[@]}" ;;
		*) sync_remote_individual "$@" "${RSYNC_COMPRESSION[@]}" "${RSYNC_REMOTE_SHELL[@]}" ;;
	esac
}
cmd_remote(){
	[[ -n $HOST_REMOTE_LIST ]] || die "Variable HOST_REMOTE_LIST is not defined."
#	VICE VERSA
	user=$(whoami); host=$(cat /etc/hostname)
	local src=$user"@"$host
	[[ $src == ${HOST_REMOTE_LIST[0]} ]] && remote_dest=${HOST_REMOTE_LIST[1]} || remote_dest=${HOST_REMOTE_LIST[0]}
	remote_catalog "$@"
}

cmd_remote_neo(){
	remote_dest="$1"; shift;
	user=$( echo $remote_dest | grep -o "[^@]*" | head -n 1 )
	host=$( echo $remote_dest | grep -o "[^@]*" | tail -n 1 )
	remote_catalog "$@"
}

cmd_local(){
	host=$(cat /etc/hostname)
	case "$1" in 
		files) shift; sync_local_files "$@" ;;
	esac
}
cmd_portable(){
#	mkdir -p $dst_hard
	
	user=$(whoami)
	case "$1" in
		wd) shift; sync_portable_media "$@" ;;
		files) shift; sync_portable_files "$@" ;;
		*) die "Incorrect command: $1"  ;;
	esac
#	mkdir -p $dst_flash
#	rsync_files  "$HOME" "$dst_hard"
#	rsync_files "$dst_hard$HOME" "$HOME"
	
#	rsync_files "$HOME" "$dst_flash"
#	rsync_files "$dst_flash$HOME" "$HOME"

}

cmd_test(){
	sync_local_files "$@"
# 	-rtvucpRE
#	-r --recursive recurse into directories	
#	-t --times preserve modification times
#	-u --update skip files that are newer on the receiver
#	-c --checksum skip based on checksum, not mod-time & size
# 	-p --perms preserve permissions
#	-v --verbose
#	-R --relative use relative path names	
#	-E --executability preserve executability

}

cmd_rsync(){
	rsync_alone "$@"
}
#
# END subcommand functions 
#
PROGRAM="${0##*/}"
COMMAND="$1"

case "$1" in
	version|--version) shift; cmd_version "$@" ;;
	help|--help) shift; cmd_usage "$@" ;;
	[a-z]*@[a-z0-9.-]*) cmd_remote_neo "$@" ;;
	remote) shift; cmd_remote "$@" ;;
	local) shift; cmd_local "$@" ;;
	portable) shift; cmd_portable "$@" ;;
	test) shift; cmd_test "$@" ;;
	*) cmd_rsync "$@" ;;

esac

exit 0
