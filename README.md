# Rsync helper script

`rsync-script.sh` is a simple shell script for easier transfer files and directories between local and remote host.
The actual transfer is done by [rsync](https://github.com/WayneD/rsync), which is a command to transfer files between local and remote host. It also manages to transfer files locally.
It is available in most of package managers.
It provides a lot of options and features.
In order to use rsync effectively and quickly on daily basis, helper script `rsync-script.sh` comes in hand. 
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
git clone 

cd rsync-script/
```

Configure file `rsync-script.sh` to fit a particular environment(HOSTS, dirs, files,...etc.) (see below CUSTOMIZATION)

```
make install

```

## Customization 

The script provides section `CUSTOMIZABLE SCRIPT VARIABLES` where variables can be modified to a particular needs of each user.
Most of the variables should work right from the start.
The only variable to take care of `HOST_REMOTE_LIST`.
For example `HOST_REMOTE_LIST=( user1@desktop1 user1@desktop2 )`.
Right now it only works for two hosts(one must be local and the other one remote - to work on either side without modify configuration).
If more than 2 hosts are defined, only first two are prioritized.
Or the remote host can be explicitly defined in a command line.

Other configuration can be done in functions started as `rsync-*()` for example `rsync-dirs` or `rsync-files`.
Those functions can be found in `rsync functions` section.
Mainly list of directories should be changed to fit to a particular environment. 

## Usage

```
Usage:  rs remote|USER@HOST files|dirs|media|etc pull|push [RSYNCOPTIONS]
                Transfer what is defined in rsync_[files|dirs|media|etc]() functions.
        rs remote|USER@HOST pull|push FILE|DIR [RSYNCOPTIONS]
                Transfer FILE or DIR.
        rs remote|USER@HOST ls DIR [RSYNCOPTIONS]
                List directory contents on remote host.
        rs remote|USER@HOST diff FILE [RSYNCOPTIONS]
                Compare local and remote FILE.
        rs local media push|pull [RSYNCOPTIONS]
                Transfer what is defined in rsync_media() function locally.
        rs help
                Show this help text.
        rs version
                Show version information.

```

## Simple examples

 - `rs remote ls .` - Print out list of files in a current directory(`.`) on remote host. If it exist on remote host.
 - `rs remote push dir/ -r` - Push directory and its content (`-r`) to remote host. Directory is defined with relative path.
 - `rs remote diff compare.txt` - Print out differences between local `compare.txt` and remote one.
 - `rs remote files pull --dry-run` - Find candidates(`--dry-run` - rsync option) for pulling files and directories defined in function `rsync-files`

## Dependencies

 - `rsync` - transfers files
 - `diff` - compares content of two files

## Author

Michal
