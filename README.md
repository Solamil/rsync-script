# Rsync helper script

`rsync-script.sh` is a simple shell script for easier transfer files and directories between local and remote host.
The actual transfer is done by [rsync](https://github.com/WayneD/rsync), which is a command to transfer files between local and remote host. It also manages to transfer files locally.
It is available in most of package managers.
It provides a lot of options and features.
In order to use rsync effectively and quickly on daily basis, helper script `rsync-script.sh` comes in hand. Don't think about what sort of options to use ever again.  
This script allows to `push` or `pull` changes or new directories and files to or from remote host.
The same logic as used in git repositories.

The script comes with an option to compare two files by `diff` command between local and remote one.
Additional options for rsync can be append to the command. 

## Use cases

 - Transfer individual files with predefined rsync options in the script.
 - Maintaining the same or similiar configuration on between multiple devices.
 - If computer is freshly reinstalled, the same configuration from another computer can be pulled by one command.
 - Backups

## Installation

```
git clone https://github.com/Solamil/rsync-script
cd rsync-script/
```

Configure file `rsync-script.sh` to fit particular environment. Mainly variables `RS_USER` and `RS_HOST`  (see below CUSTOMIZATION)

```
make install
```

## Customization 

The script provides section `CUSTOMIZABLE SCRIPT VARIABLES` where variables can be modified to a particular needs of each user.
Most of the variables should work right from the start.
The only variables to take care of are environment variable `RS_USER` and `RS_HOST`.
Ideally those variables can be set in config file `~/.config/rsync/rsrc`.
Either define them explicitly in command line e.g. `export RS_USER="test" RS_HOST="my_desktop"` or in a file.  

The other configuration what file to avoid or add is done by rsync filters in each directory.
## Usage

```
Usage: 	rs home [local] pull|push [RSYNCOPTIONS]
		Transfer files in $HOME directory, considering rsync filters.
	rs media [local] pull|push [RSYNCOPTIONS]
		Transfer specified in rsync_media() function.
	rs ls [DIR] [RSYNCOPTIONS]
		List directory contents on remote host.
	rs diff FILE [RSYNCOPTIONS]
		Show diff between local and remote FILE.		
	rs FILE|DIR pull|push [RSYNCOPTIONS]
		Transfer specified FILE or DIR.
	rs host [remote_user] [remote_host]
		Print content of variables RS_USER and RS_HOST and optionally set these variables. 
	rs config host remote_user [remote_host] 
		Set variables RS_USER and RS_HOST in config file.
	rs help
		Show this help text.
	rs version
		Show version information.

```

## Simple examples

 - `rs ls .` - Print out list of files in a current directory(`.`) on remote host. If it exist on remote host. It is much like `ls -la` on local machine.
 - `rs dir/ push -r` - Push directory and its content (`-r`) to remote host. Directory is defined with relative path.
 - `rs diff compare.txt` - Print out differences between local `compare.txt` and remote one.
 - `rs files pull --dry-run` - Find candidates(`--dry-run` - rsync option) for pulling files and directories defined in function `rsync-files`

## Dependencies

 - `rsync` - transfers files
 - `diff` - compares content of two files

## Author

Michal
