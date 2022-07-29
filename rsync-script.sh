#!/bin/sh
#
# BEGIN CUSTOMIZABLE SCRIPT VARIABLES 
#

RSYNC="rsync"
RSYNC_DEFAULT_OPTS=( --human-readable --progress --itemize-changes )
RSYNC_COMPRESSION=( --compress --compress-choice=zstd --compress-level=22 )
RSYNC_RSH=( "ssh -T -o Compression=no -x" )
# RSYNC_OPTS=( --recursive --times --update --verbose  ) # not in use
RSYNC_CONF_DIR="$XDG_CONFIG_HOME/rsync"
GLOBAL_FILTER="$RSYNC_CONF_DIR/global-filter"
TMP_DIR="/tmp"
RSYNC_GLOBAL_FILTER=( --filter="merge $GLOBAL_FILTER" )
LOCALUSER=$(whoami)
LOCALHOST="$(cat /etc/hostname)"

# Define for yourself default remote destination
RS_USER="${RS_USER:-}"
RS_HOST="${RS_HOST:-}"
RS_REMOTE_DEST="$RS_USER@$RS_HOST:"

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
set_remote_dest(){

	remote_dest=$RS_REMOTE_DEST

}
diff_files(){
	prefix=$1	 
	remote_files=$(find $TMP_DIR$prefix -name "*" -type f)
	for i in $remote_files; do
		file=${i#$TMP_DIR}
		diff --color=auto "$i" "$file"
	done
}
#
# END platform definable
#

#
# BEGIN rsync functions
#

rsync_alone(){
	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -e "${RSYNC_RSH[@]}" \
	"$@"
#	-rtvcpRE \
}

rsync_individual(){
	local src=$1 dst=$2; shift 2; local args="$@"
#	PUSH without /
	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -e "${RSYNC_RSH[@]}" \
	-tvupE ${args[@]} \
	$src $dst
	
}

rsync_media(){
	local src=$1 dst=$2; shift 2; local args="$@"
	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -e "${RSYNC_RSH[@]}" \
	-rtvpR --ignore-existing ${args[@]} \
	"${RSYNC_GLOBAL_FILTER[@]}" \
	$src/./{Movies/,Music/,docs/,Phone/} \
	$dst/

# 	"$RSYNC_GLOBAL_FILTER" 
#	--ignore-existing \
}

rsync_etc(){
	local src=$1 dst=$2; shift 2; local args="$@"
	sudo $RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -e "${RSYNC_RSH[@]}" \
	-rtvupRE --links ${args[@]} \
	$src/./{sudoers,locale.gen,locale.conf,pacman.d/hooks/} \
	$src/./ssh/sshd_config \
	$dst/
#	/etc/pulse/default.pa \
}

rsync_dirs(){
	local src=$1 dst=$2; shift 2; local args="$@"
#	--backup-dir="/tmp/" \
	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -e "${RSYNC_RSH[@]}" \
	-rtvupRE --links ${args[@]} --info=NAME1 -F \
	$src/./{dl/,docs/,scripts/,pics/,devel/} \
	$dst/

#	-F \
#	--delete-after "$RSYNC_GLOBAL_FILTER" \
}

rsync_files(){
	local src=$1 dst=$2; shift 2; local args="$@"

	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -e "${RSYNC_RSH[@]}" \
	-rtvupRE --links ${args[@]} --info=NAME1 -F \
	$src/./{.bitmonero/,.imwheelrc} \
	$src/./{.config/,scripts/,.local/share/} \
	$dst/
}

#	$src/./ \


#
# END rsync functions
#

cmd_version(){
	cat <<-_EOF
	 --------------------------------------------------------------------
	| 				rs				     |
	|								     |
	|    rsync shell script for easier transfer files and directories    |
	|								     |
	| 			   version: v0.2			     |
	|								     |
	|			      Michal				     |
	 --------------------------------------------------------------------
	_EOF
}

cmd_usage(){
	cmd_version
	echo
	cat <<-_EOF
	Usage: 	$PROGRAM files [local] [portable] pull|push [RSYNCOPTIONS]
	                Transfer specified in rsync_files() function.
		$PROGRAM dirs [local] pull|push [RSYNCOPTIONS]
	                Transfer specified in rsync_dirs() function.
		$PROGRAM media [local] pull|push [RSYNCOPTIONS]
	                Transfer specified in rsync_media() function.
		$PROGRAM etc [local] pull|push [RSYNCOPTIONS]
	                Transfer specified in rsync_etc() function.
	        $PROGRAM ls [DIR] [RSYNCOPTIONS]
	        	List directory contents on remote host.
	        $PROGRAM diff FILE [RSYNCOPTIONS]
	        	Show diff between local and remote FILE.		
		$PROGRAM FILE|DIR pull|push [RSYNCOPTIONS]
			Transfer specified FILE or DIR.
	        $PROGRAM help
	        	Show this help text.
	        $PROGRAM version
	        	Show version information.

	_EOF
}

cmd_tmp(){
	set_remote_dest

	{ echo "$1" | grep -q "^/"; } && src="$1" || src="$(pwd)/$1"; shift;
	
	rsync_individual "$remote_dest$src" "$TMP_DIR$src" "--mkpath $@"


}

cmd_ls(){
	set_remote_dest

	if [[ $# -eq 0 ]]; then
		src="$(pwd)/." 
	else 
		{ echo "$1" | grep -q "^/"; } && src="$1" || src="$(pwd)/$1"; shift
	fi

	rsync_individual "$remote_dest$src" "" "$@"

}

cmd_diff(){
	cmd_tmp "$@"
	diff --color=always "$src" "$TMP_DIR$src"
}

cmd_files(){
	case "$1" in
		local) shift; remote_dest="$HOME/data/portable-home/$host" ;;
		portable) shift; remote_dest="$HOME/flashdrive/portable-home" ;;
		*) set_remote_dest ;;
	esac 

	case "$1" in
		pull) shift; rsync_files "$remote_dest$HOME" "$HOME" "$@" ;;
		push) shift; rsync_files "$HOME" "$remote_dest$HOME" "$@" ;;
		diff) shift; rsync_files "$remote_dest$HOME" "$TMP_DIR$HOME" "--mkpath --compare-dest="$HOME/" $@"; diff_files "$HOME" ;;
		*) die "Usage: $PROGRAM $COMMAND [local] [portable] pull|push|diff [RSYNCOPTIONS]"  ;;
	esac


}

cmd_dirs(){
	set_remote_dest
	case "$1" in
		portable) shift; remote_dest="$HOME/flashdrive/portable-home" ;;
		*) set_remote_dest ;;
	esac 
	case "$1" in
		pull) shift; rsync_dirs "$remote_dest$HOME" "$HOME" "$@" ;; 
		push) shift; rsync_dirs "$HOME" "$remote_dest$HOME" "$@" ;;
		*) die "Usage: $PROGRAM $COMMAND [portable] pull|push [RSYNCOPTIONS]"  ;;
	esac
}

cmd_etc(){
	set_remote_dest
	
	case "$1" in
		pull) shift; rsync_etc "$remote_dest/etc" "/etc" "$@" ;; 
		push) shift; rsync_etc "/etc" "$remote_dest/etc" "$@" ;;
		*) die "Usage: $PROGRAM $COMMAND pull|push [RSYNCOPTIONS]"  ;;
	esac
}

cmd_media(){
	set_remote_dest

	hardrive="/media/$user/HardDrive"
	local src=$hardrive 
	local dest=$remote_dest$hardrive

	case "$1" in
		local) shift; dest="/media/$user/ExtDrive" ;;
	esac 
	
	case "$1" in
		pull) shift; local SRC="$dest" DEST="$src" ;;
		push) shift; local SRC="$src" DEST="$dest" ;; # Syncing it back
		*) die "Usage: $PROGRAM $COMMAND [local] pull|push [RSYNCOPTIONS]"  ;;
	esac
	rsync_media $SRC $DEST "$@"
}

cmd_individual(){
	[[ $# -eq 0 ]] && { cmd_usage; exit 0; }


	COMMAND="FILE"
	{ echo "$1" | grep -q "^/"; } && src="$1" || src="$(pwd)/$1";
	[[ -d $src ]] && { echo "$1" | grep -vq "/$"; } && src=$src"/"

	set_remote_dest
	
	case "$2" in
		pull) shift 2; rsync_individual "$remote_dest$src" "$src" "$@"; return ;;
		push) shift 2; rsync_individual "$src" "$remote_dest$src" "$@"; return ;;
		*) die "Usage: $PROGRAM $COMMAND pull|push [RSYNCOPTIONS]"  ;;
	esac

	rsync_alone "$@"
}

#
# END subcommand section    
#

PROGRAM="${0##*/}"
COMMAND="$1"

case "$1" in
 	version|--version) shift; cmd_version "$@" ;;
 	help|--help) shift; cmd_usage "$@" ;;
	etc) shift; cmd_etc "$@" ;;
	diff) shift; cmd_diff "$@" ;;
	"ls") shift; cmd_ls "$@" ;;
	files) shift; cmd_files "$@" ;;
	dirs) shift; cmd_dirs "$@" ;;
	media) shift; cmd_media "$@" ;;
	*) cmd_individual "$@" ;;
	
esac

exit 0
