#!/bin/sh
#
# BEGIN CUSTOMIZABLE SCRIPT VARIABLES 
#

RSYNC="rsync"
RS_DIR="${RS_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}}/rsync"

# Local side
USER=$(whoami)
HOST="$(cat /etc/hostname)"

# Remote side
RS_USER="${RS_USER:-}"
RS_HOST="${RS_HOST:-}"

MEDIA_DIR=""
PORTABLE="" 
PORTABLE_HOME=""

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
set_prefix(){ prefix="$RS_USER@$RS_HOST:"; }


#
# END platform definable
#

#
# BEGIN rsync functions
#

rsync_func(){
	$RSYNC --human-readable --progress --itemize-changes --verbose \
		-e "ssh -T -o Compression=no -x" \
		"$@"
}


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
	| 			   version: v0.3			     |
	|								     |
	|			      Michal				     |
	 --------------------------------------------------------------------
	_EOF
}

cmd_usage(){
	cmd_version
	echo
	cat <<-_EOF
	Usage: 	$PROGRAM [FILE|DIR] [DEST] pull|push [RSYNCOPTIONS]
	                Transfer specified FILE or DIR.
	        $PROGRAM - [DEST] pull|push [RSYNCOPTIONS]
	                Read files from from stdin.
	        $PROGRAM home [local] pull|push [RSYNCOPTIONS]
	                Transfer files in $HOME directory, considering rsync filters.
	        $PROGRAM media [local] pull|push [RSYNCOPTIONS]
	                Transfer files in MEDIA directory.
	                Media directories are defined by variables MEDIA_DIR, PORTABLE.
	        $PROGRAM ls [DIR] [RSYNCOPTIONS]
	        	List directory contents on remote host.
	        $PROGRAM help
	        	Show this help text.
	        $PROGRAM version
	        	Show version information.

	More information may be found in the rs(1) man page.
	_EOF
}

cmd_ls(){
	set_prefix

	if [ $# -eq 0 ]; then
		src=$(readlink -f ".")
	else 
		src=$(readlink -f "$1")
		shift
	fi

	echo "$prefix"
	rsync_func "$@"  \
		--list-only \
		"$prefix$src" "" 

}

cmd_home(){
	case "$1" in
		local) shift; prefix=$PORTABLE_HOME ;;
		*) set_prefix ;;
	esac 

	case "$1" in
		pull) shift; echo "$prefix =========> $USER@$HOST"
			SRC="$prefix$HOME/./" DEST="$HOME/"
			;; 
		push) shift; echo "$USER@$HOST =========> $prefix"
			SRC="$HOME/./" DEST="$prefix$HOME/" 
			;;
		*) die "Usage: $PROGRAM $COMMAND pull|push [RSYNCOPTIONS]"  
			;;
	esac

	rsync_func "$@" \
		--recursive --times --update --perms --executability \
		--relative --filter="dir-merge /.rsync-filter" --hard-links --links \
		"$SRC" "$DEST"
}

cmd_media(){
	set_prefix

	src=$MEDIA_DIR
	dest=$prefix$MEDIA_DIR

	case "$1" in
		local) shift; dest=$PORTABLE
			;;
	esac 
	
	case "$1" in
		pull) shift; echo "$dest =========> $USER@$HOST"
			SRC="$dest/./" DEST="$src" 
			;;
		push) shift; echo "$USER@$HOST =========> $dest"
			SRC="$src/./" DEST="$dest" 
			;; # Syncing it back
		*) die "Usage: $PROGRAM $COMMAND [local] pull|push [RSYNCOPTIONS]"  ;;
	esac

	rsync_func "$@" \
		--recursive --times --perms --relative --ignore-existing \
		--filter="dir-merge /.rsync-filter" \
		"$SRC" "$DEST"
}

cmd_stdin(){

	set_prefix
	if [ "$1" != "pull" ] && [ "$1" != "push" ]; then
		dest=$(readlink -f "$1")
		shift
	else
		dest="$(pwd)/"
	fi

	case "$1" in
		pull) shift; SRC="$prefix$(pwd)/" DEST=$dest
			;;
		push) shift; SRC=$dest DEST="$prefix$(pwd)/"
			;;
		*) die "Usage: $PROGRAM $COMMAND [DEST] pull|push [RSYNCOPTIONS]"  ;;
	esac
	rsync_func "$@" \
		--times --update --perms --executability \
		"$SRC" "$DEST"
}

cmd_individual(){
	[ $# -eq 0 ] && { cmd_ls; exit 0; }

	COMMAND="FILE"
	set_prefix
	src=$(readlink -f "$1")

	[ -d "$src" ] && src=$src"/"
		
	shift

	if [ "$1" != "pull" ] && [ "$1" != "push" ]; then
		dest=$(readlink -f "$1")
		shift
	else
		dest=$src	
	fi

	case "$1" in
		pull) shift; echo "$RS_USER@$RS_HOST =========> $USER@$HOST"
			SRC="$prefix$src" DEST="$dest" 
			;;
		push) shift; echo "$USER@$HOST =========> $RS_USER@$RS_HOST"
			SRC="$src" DEST="$prefix$dest"
			;;
		*) die "Usage: $PROGRAM [$COMMAND] [DEST] pull|push [RSYNCOPTIONS]"  
			;;
	esac

	rsync_func "$@" \
		--times --update --perms --executability \
		"$SRC" "$DEST"
}

PROGRAM="${0##*/}"
COMMAND="$1"

# Further personal customization in the script file,
# without "make install" all over again

[ -f "$RS_DIR/rsrc" ] && . "$RS_DIR"/rsrc
#
# END subcommand section    
#


case "$1" in
 	version|--version) shift; cmd_version "$@" ;;
 	help|--help) shift; cmd_usage "$@" ;;
	"ls") shift; cmd_ls "$@" ;;
	home) shift; cmd_home "$@" ;;
	media) shift; cmd_media "$@" ;;
	"-") shift; cmd_stdin "$@" ;;
	*) cmd_individual "$@" ;;
	
esac

exit 0
