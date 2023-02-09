# Rsync helper script
Rs is a shell script with set of options for easier using rsync command on daily basis between two remote hosts or locally as well.
The actual transfer is done by [rsync](https://github.com/WayneD/rsync), which is a command to transfer files between local and remote host. It also manages to transfer files locally.
It is available in most of package managers.
It provides a lot of options and features.
This script allows to `push` or `pull` changes or new directories and files to or from remote host.
The same logic as used in git repositories.

Additional options for rsync can be append to the command. 

## Use cases

 - Sync individual files with predefined rsync options in the script.
 - Maintaining the same or similiar configuration on multiple devices.
 - If computer is freshly reinstalled, the same configuration from another computer can be pulled by one command.
 - Backup on local portable devices.

## Installation

```
git clone https://github.com/Solamil/rsync-script
cd rsync-script/
```

Configure file `rsync-script.sh` to fit particular environment. Mainly variables `RS_USER` and `RS_HOST`  (see below CUSTOMIZATION)
Then only execute following command.

```
make install
```

## Customization 

The only variables to take care of are environment variable `RS_USER` and `RS_HOST`.
Variables `RS_USER` and `RS_HOST` are remote side.
The script provides section `CUSTOMIZABLE SCRIPT VARIABLES` where variables can be modified to a particular needs of each user.
Most of the variables should work right from the start.
Ideally those variables can be set in config file `$HOME/.config/rsync/rsrc`.
Either define them explicitly in command line e.g. `export RS_USER="test" RS_HOST="my_desktop"` or in a file.  

Whole new behavior can be overriden or set in `$HOME/.config/rsync/rsrc`.
## Usage

```
Usage: 	rs home [local] pull|push [RSYNCOPTIONS]
		Sync files in $HOME directory, considering rsync filters.
	rs media [local] pull|push [RSYNCOPTIONS]
		Sync MEDIA directories is defined by variables MEDIA_DIR, PORTABLE.
	rs ls [DIR] [RSYNCOPTIONS]
		List directory contents on remote host.
	rs [FILE|DIR] [DEST] pull|push|local [RSYNCOPTIONS]
		Sync specified FILE or DIR.
	rs - [DEST] pull|push [RSYNCOPTIONS]
		Sync files from stdin in current directory.	
	rs help
		Show this help text.
	rs version
		Show version information.
		
More information may be found in the rs(1) man page.
```

## Simple examples

 - `rs ls .` - Print out list of files in a current directory(`.`) on remote host. If it exist on remote host. It is much like `ls -la` on local machine.
 - `rs home pull -n` - Find candidates(`-n, --dry-run`, rsync option) for pulling files and directories defined in `$HOME` directory.
 - `rs dir/ push -r` - Push directory and its content (`-r, --recursive`, rsync-option) to remote host. Directory is defined with relative path.
 - `rs path/to/file/test.txt pathtofile/ push` - Transfer `test.txt` from directory `path/to/file/` to directory `pathtofile/` on a remote side.

## Dependencies

 - `rsync`, `ssh` - transfers files, default transfer over ssh

## Author

Solamil 
