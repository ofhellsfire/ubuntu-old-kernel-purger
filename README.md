# old-kernel-purger

old-kernel-purger is a simple bash script that allows observing and deleting old kernel packages for Ubuntu 14.

## Description

The script heavily relies on __apt__ package manager to remove old packages.
__old-kernel-purger__ requires admin privileges and Bash version >= 4.

The script supports simple exclude mechanism by reading __.kernelkeep__ file that holds versions to be excluded from purging.
To add exclusion: create __.kernelkeep__ file (if it's missing) and put desired version to be excluded in a separate line.

__old-kernel-purger__ supports so called _dry-run_ which reveal what packages is going to be removed according the configuration without any actions. This can be helpful for understanding what packages the script is going to remove.

The script excludes the current running kernel version automatically.
By default, in addition to the current kernel, it excludes 2 older versions as well. It's possible to control this parameter via command-line arguments.

## Usage

```
Deletes old kernel packages for Ubuntu 14.04 (requires root privileges)

Usage:
-h, --help              Print usage
-d, --dry-run           Run without making real actions.
                        Useful for examining what packages
                        will be removed. Default: false
-y, --yes               Run in non-interactive mode.
                        Default: false
-k <num>, --keep <num>  Specify how many latest versions to keep.
                        Default: 2
```
