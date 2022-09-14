#!/bin/sh
#
# BEGIN CUSTOMIZABLE SCRIPT VARIABLES 
#

RSYNC="rsync"
RSYNC_DEFAULT_OPTS=( --human-readable --progress --itemize-changes )
RSYNC_COMPRESSION=( --compress --compress-choice=zstd --compress-level=22 )
RSYNC_RSH=( "ssh -T -o Compression=no -x" )
RS_DIR="${RS_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}}/rsync"
TMP_DIR="/tmp"

# Local side
USER=$(whoami)
HOST="$(cat /etc/hostname)"

# Remote side
RS_USER="${RS_USER:-}"
RS_HOST="${RS_HOST:-}"

MEDIA_DIR=""
PORTABLE="" 
PORTABLE_HOME=""

INDIVIDUAL_OPTS=( -tvupE )
HOME_OPTS=( -rtuvpERFH --links )
MEDIA_OPTS=( -rtvpRF --ignore-existing )



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
	$RSYNC "${RSYNC_DEFAULT_OPTS[@]}" -e "${RSYNC_RSH[@]}" \
	$@
#	-rtvcpRE \
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
	                If no file is specified then program reads from stdin.
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

	if [[ $# -eq 0 ]]; then
		src="$(pwd)/." 
	else 
		{ echo "$1" | grep -q "^/"; } && src="$1" || src="$(pwd)/$1"; shift
	fi
	echo "$USER@$HOST =========> $prefix"
	rsync_func "$@" "$prefix$src" "" 

}

cmd_home(){
	case "$1" in
		portable) shift; prefix=$PORTABLE_HOME ;;
		*) set_prefix ;;
	esac 

	case "$1" in
		pull) shift; echo "$prefix =========> $USER@$HOST"
			local SRC="$prefix$HOME/./" DEST="$HOME/"
			;; 
		push) shift; echo "$USER@$HOST =========> $prefix"
			local SRC="$HOME/./" DEST="$prefix$HOME/" 
			;;
		*) die "Usage: $PROGRAM $COMMAND pull|push [RSYNCOPTIONS]"  
			;;
	esac
	rsync_func "$@" ${HOME_OPTS[@]} $SRC $DEST
}

cmd_media(){
	set_prefix

	local src=$MEDIA_DIR
	local dest=$prefix$MEDIA_DIR

	case "$1" in
		portable) shift; dest=$PORTABLE
			;;
	esac 
	
	case "$1" in
		pull) shift; echo "$dest =========> $USER@$HOST"
			local SRC="$dest/./" DEST="$src" 
			;;
		push) shift; echo "$USER@$HOST =========> $dest"
			local SRC="$src/./" DEST="$dest" 
			;; # Syncing it back
		*) die "Usage: $PROGRAM $COMMAND [local] pull|push [RSYNCOPTIONS]"  ;;
	esac
	rsync_func "$@" ${MEDIA_OPTS[@]}  $SRC $DEST
}

cmd_individual(){
	[[ $# -eq 0 ]] && { cmd_ls; exit 0; }

	COMMAND="FILE"
	set_prefix

	case "$1" in
		pull) 	local SRC="$prefix$(pwd)/" DEST="$(pwd)/" files=( --files-from="-" )
			shift ;;
		push)	local SRC="$(pwd)/" DEST="$prefix$(pwd)/" files=( --files-from="-" )
			shift ;;
		*)	
			{ echo "$1" | grep -q "^/"; } && src="$1" || src="$(pwd)/$1";
			[[ -d $src ]] && { echo "$1" | grep -vq "/$"; } && src=$src"/"
			shift

			if ! [[ $1 =~ pull|push ]]; then
				{ echo "$1" | grep -q "^/"; } && dest="$1" || dest="$(pwd)/$1";
				shift
			else
				dest=$src	
			fi

			case "$1" in
				pull) shift; echo "$RS_USER@$RS_HOST =========> $USER@$HOST"
					local SRC="$prefix$src" DEST="$dest" 
					;;
				push) shift; echo "$USER@$HOST =========> $RS_USER@$RS_HOST"
					local SRC="$src" DEST="$prefix$dest"
					;;
				*) die "Usage: $PROGRAM [$COMMAND] [DEST] pull|push [RSYNCOPTIONS]"  
					;;
			esac
			;;
	esac


		
	rsync_func "$@" ${INDIVIDUAL_OPTS[@]} ${files[@]} $SRC $DEST
}

PROGRAM="${0##*/}"
COMMAND="$1"

# Further personal customization in the script file,
# without "make install" all over again

[ -f $RS_DIR/rsrc ] && . $RS_DIR/rsrc
#
# END subcommand section    
#


case "$1" in
 	version|--version) shift; cmd_version "$@" ;;
 	help|--help) shift; cmd_usage "$@" ;;
	"ls") shift; cmd_ls "$@" ;;
	home) shift; cmd_home "$@" ;;
	media) shift; cmd_media "$@" ;;
	*) cmd_individual "$@" ;;
	
esac

exit 0
