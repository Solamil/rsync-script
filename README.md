# Rsync helper script

`rsync-script.sh` is a simple shell script for easier transfer files and directories between local and remote host.
The actual transfer is done by [rsync](https://github.com/WayneD/rsync), which is a command to transfer files between local and remote host. It also manages to transfer files locally.
It is available in most of package managers.
It provides a lot of options and features.
In order to use rsync effectively and quickly on daily basis, helper script `rsync-script.sh` comes in hand. Don't think about what sort of options to use ever again.  
This script allows to `push` or `pull` changes or new directories and files to or from remote host.
The same logic as used in git repositories.

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
Then only execute following command.

```
make install
```

## Customization 

Variables `RS_USER` and `RS_HOST` are remote side.
The script provides section `CUSTOMIZABLE SCRIPT VARIABLES` where variables can be modified to a particular needs of each user.
Most of the variables should work right from the start.
The only variables to take care of are environment variable `RS_USER` and `RS_HOST`.
Ideally those variables can be set in config file `$HOME/.config/rsync/rsrc`.
Either define them explicitly in command line e.g. `export RS_USER="test" RS_HOST="my_desktop"` or in a file.  

Whole new behavior can be overriden or set in `$HOME/.config/rsync/rsrc`.
## Usage

```
Usage: 	rs home [local] pull|push [RSYNCOPTIONS]
		Transfer files in $HOME directory, considering rsync filters.
	rs media [local] pull|push [RSYNCOPTIONS]
		Media directories is defined by variables HARDRIVE, EXTDRIVE.
	rs ls [DIR] [RSYNCOPTIONS]
		List directory contents on remote host.
	rs [FILE|DIR] [DEST] pull|push [RSYNCOPTIONS]
		Transfer specified FILE or DIR.
		If no file is specified then program reads from stdin.
	rs help
		Show this help text.
	rs version
		Show version information.

```

## Simple examples

 - `rs ls .` - Print out list of files in a current directory(`.`) on remote host. If it exist on remote host. It is much like `ls -la` on local machine.
 - `rs home pull -n` - Find candidates(`-n, --dry-run`, rsync option) for pulling files and directories defined in `$HOME` directory.
 - `rs dir/ push -r` - Push directory and its content (`-r, --recursive`, rsync-option) to remote host. Directory is defined with relative path.
 - `rs path/to/file/test.txt pathtofile/ push` - Transfer `test.txt` from directory `path/to/file/` to directory `pathtofile/` on a remote side.

## Dependencies

 - `rsync`, `ssh` - transfers files, default transfer over ssh

## Author

Michal < michal@michalkukla.xyz >
