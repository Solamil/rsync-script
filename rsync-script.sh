#!/bin/sh
#
# BEGIN CUSTOMIZABLE SCRIPT VARIABLES 
#

RSYNC="rsync"
RSYNC_DEFAULT_OPTS=( --human-readable --progress --itemize-changes )
RSYNC_COMPRESSION=( --compress --compress-choice=zstd --compress-level=22 )
RSYNC_RSH=( "ssh -T -o Compression=no -x" )
# RSYNC_OPTS=( --recursive --times --update --verbose  ) # not in use
RS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rsync"
GLOBAL_FILTER="$RS_DIR/global-filter"
TMP_DIR="/tmp"
RSYNC_GLOBAL_FILTER=( --filter="merge $GLOBAL_FILTER" )
USER=$(whoami)
HOST="$(cat /etc/hostname)"

RS_USER="${RS_USER:-}"
RS_HOST="${RS_HOST:-}"

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
set_remote_dest(){ remote_dest="$RS_USER@$RS_HOST:"; }

set_host(){
	sed -i "s/^RS_USER=.*/RS_USER=\"$1\"/" $RS_DIR/rsrc
	RS_USER=$1
	if [[ -n "$2" ]]; then
		[[ $HOST == "$2" ]] && die "Error: The name \"$2\" for remote host is identical as for localhost." 
		sed -i "s/^RS_HOST=.*/RS_HOST=\"$2\"/" $RS_DIR/rsrc
		RS_HOST=$2
	fi

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

rsync_without_args(){
	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -e "${RSYNC_RSH[@]}" \
	$@
#	-rtvcpRE \
}

rsync_individual(){
#	local src=$1 dst=$2; shift 2; local args="$@"
#	PUSH without /
	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -e "${RSYNC_RSH[@]}" \
	-tvupE $@
#	$src $dst
	
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

rsync_files(){
	local src=$1 dst=$2; shift 2; local args="$@"

	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -e "${RSYNC_RSH[@]}" \
	-rtvupRE --links ${args[@]} --info=NAME1 -F \
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
	Usage: 	$PROGRAM files [local] [portable] pull|push|diff [RSYNCOPTIONS]
	                Transfer specified in rsync_files() function.
		$PROGRAM dirs [local] pull|push [RSYNCOPTIONS]
	                Transfer specified in rsync_dirs() function.
		$PROGRAM media [local] pull|push [RSYNCOPTIONS]
	                Transfer specified in rsync_media() function.
	        $PROGRAM ls [DIR] [RSYNCOPTIONS]
	        	List directory contents on remote host.
	        $PROGRAM diff FILE [RSYNCOPTIONS]
	        	Show diff between local and remote FILE.		
		$PROGRAM FILE|DIR [DEST] pull|push [RSYNCOPTIONS]
			Transfer specified FILE or DIR.
		$PROGRAM host [remote_user] [remote_host]
			Print content of variables RS_USER and RS_HOST and optionally set these variables. 
	        $PROGRAM help
	        	Show this help text.
	        $PROGRAM version
	        	Show version information.

	_EOF
}

cmd_tmp(){
	set_remote_dest

	{ echo "$1" | grep -q "^/"; } && src="$1" || src="$(pwd)/$1"; shift;
	
	rsync_individual "--mkpath $@" "$remote_dest$src" "$TMP_DIR$src"


}

cmd_ls(){
	set_remote_dest

	if [[ $# -eq 0 ]]; then
		src="$(pwd)/." 
	else 
		{ echo "$1" | grep -q "^/"; } && src="$1" || src="$(pwd)/$1"; shift
	fi

	rsync_without_args "$@" "$remote_dest$src" "" 

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
		pull) shift; echo "$RS_USER@$RS_HOST ======> $USER@$HOST"
			rsync_files "$remote_dest$HOME" "$HOME" "$@" ;;
		push) shift; echo "$USER@$HOST =========> $RS_USER@$RS_HOST"
			rsync_files "$HOME" "$remote_dest$HOME" "$@" ;;
		diff) shift; rsync_files "$remote_dest$HOME" "$TMP_DIR$HOME" "--mkpath --compare-dest="$HOME/" $@"; diff_files "$HOME" ;;
		*) die "Usage: $PROGRAM $COMMAND [local] [portable] pull|push|diff [RSYNCOPTIONS]"  ;;
	esac


}

cmd_dirs(){
	case "$1" in
		portable) shift; remote_dest="$HOME/flashdrive/portable-home" ;;
		*) set_remote_dest ;;
	esac 

	case "$1" in
		pull) shift; echo "$RS_USER@$RS_HOST =========> $USER@$HOST"
			rsync_individual -rRF --links $@ "$remote_dest$HOME/./" "$HOME/"
			;; 
		push) shift; echo "$USER@$HOST =========> $RS_USER@$RS_HOST"
			rsync_individual -rRF --links $@ "$HOME/./"  "$remote_dest$HOME/./"
			;;
		*) die "Usage: $PROGRAM $COMMAND pull|push [RSYNCOPTIONS]"  
			;;
	esac
}

cmd_media(){
	set_remote_dest

	hardrive="/media/$USER/HardDrive"
	local src=$hardrive 
	local dest=$remote_dest$hardrive

	case "$1" in
		local) shift; dest="/media/$USER/ExtDrive" ;;
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
	shift

	set_remote_dest
	
	if ! [[ $1 =~ pull|push ]]; then
		{ echo "$1" | grep -q "^/"; } && dest="$1" || dest="$(pwd)/$1";
		shift
	else
		dest=$src	
	fi

	case "$1" in
		pull) shift; echo "$RS_USER@$RS_HOST =========> $USER@$HOST"
			rsync_individual "$@" "$remote_dest$src" "$dest" ; return ;;
		push) shift; echo "$USER@$HOST =========> $RS_USER@$RS_HOST"
			rsync_individual "$@" "$src" "$remote_dest$dest" ; return ;;
		*) die "Usage: $PROGRAM $COMMAND [DEST] pull|push [RSYNCOPTIONS]"  ;;
	esac

	rsync_without_args "$@"
}

cmd_config(){
	case "$1" in
		host) shift; set_host "$@" ;;
		*) die "Usage: $PROGRAM $COMMAND host remote_user [remote_host]"
	esac
}

cmd_host(){
	[[ $# -gt 0 ]] && set_host "$@"
	echo "Remote user: $RS_USER"
	echo "Remote host: $RS_HOST"
	echo "---------------------"
}

[ -f $RS_DIR/rsrc ] && . $RS_DIR/rsrc
#
# END subcommand section    
#

PROGRAM="${0##*/}"
COMMAND="$1"

case "$1" in
 	version|--version) shift; cmd_version "$@" ;;
 	help|--help) shift; cmd_usage "$@" ;;
	diff) shift; cmd_diff "$@" ;;
	"ls") shift; cmd_ls "$@" ;;
	files) shift; cmd_files "$@" ;;
	dirs) shift; cmd_dirs "$@" ;;
	media) shift; cmd_media "$@" ;;
	host) shift; cmd_host "$@" ;;
	config) shift; cmd_config "$@" ;;
	host) shift; cmd_host "$@" ;;
	*) cmd_individual "$@" ;;
	
esac

exit 0
