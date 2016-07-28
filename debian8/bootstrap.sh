#!/bin/sh -eu
# stop on error or unset variables

# version info
version() {
    echo "0.0.2"
    exit 0
}

# debian.sh usage
usage() {
    echo "Usage: debian.sh [OPTIONS]"
    echo "Bootstrap a salt master on a Debian system."
    echo ""
    echo "Mandatory arguments to long options are mandatory for short options too."
    echo "-o   directories to chown for the salt user+group"
    echo "-O   same as -o, but don't chown default directories"
    echo "-q   don't output anything"
    echo "-u   install as specific user"
    echo "-v   use verbose output (-vvv for most verbose)"
    echo ""
    echo "-h   display this help and exit"
    echo "-V   show version information and exit"
    exit 0
}


# helper functions
error() {
    text=${1:-`cat </dev/stdin`}
    verbose_printer 1 $text
}

warn() {
    text=${1:-`cat </dev/stdin`}
    verbose_printer 2 $text
}

info() {
    text=${1:-`cat </dev/stdin`}
    verbose_printer 3 $text
}

verbose_printer() {
    [ $1 -gt $verbosity ] || ( echo $text >&2 || true )
}


# default config
confirm=true
verbosity=3

nonroot=true
saltuser="salt"
saltgroup="salt"

interactive=true

# directories that should be owned by the salt user
saltowneddirs="/etc/salt /var/cache/salt /var/log/salt /var/run/salt"


# process commandline arguments
invalid_argument() {
    error "Invalid option '$0' passed, aborting."
    exit
}

process_arguments() {
    OPTIND=1
    while getopts ":foOuyhvqV:" opt; do
        info "Parsing option '$opt'..."
        case $opt in
            o)  saltowneddirs="$saltowneddirs $OPTARG";;
            O)  saltowneddirs="$OPTARG";;
            q)  quiet=true;;
            u)  saltuser=$OPTARG;;
            v)  $((verbosity++));;

            h)  usage;;
            V)  version;;
            \?) invalid_argument $OPTARG;;
        esac
    done
}

echo "Processing commandline arguments..."
process_arguments $@
echo "Done."




# can the current user access required commands?
command_exists() {
    type "$1" > /dev/null 2>&1 || return 1
}


# ensure we have certain commands available as user
requiredcommands="echo command sudo getopts rm cp chown useradd groupadd"
for command in $requiredcommands
do
    info "Checking if required command '$command' exists..."
    command_exists "$command" || {
        apt-get install $command
    } || {
        error "Can't access required command '$command', aborting."
        exit;
    }

    info "Done."
done


exit


# install salt
info "Installing required packages..."
apt-get install salt-master salt-minion
info "Done."

if [ $nonroot == true ] ; then
    # add users and groups
    info "Adding $saltgroup group..."
    groupadd -f "$saltgroup"
    info "Done."

    info "Adding ${saltuser} user..."
    id -u $saltuser || sudo useradd -g "$saltgroup" "$saltuser"
    info "Done."

    # take ownership of directories to be used by salt
    info "Taking ownership of salt directories..."
    for directory in $saltowneddirs
    do
        info "$directory"
        chown -R "$saltgroup" $directory
    done
    info "Done."
fi

# deploy salt settings
info "Deploying salt config files..."
if [ -f master ]; then
    sudo rm -f /etc/salt/master
    sudo cp master /etc/salt/
    sudo chown salt:salt /etc/salt/master
fi

if [ -f minion ]; then
    sudo rm -f /etc/salt/minion
    sudo cp minion /etc/salt/
    sudo chown salt:salt /etc/salt/minion
fi
info "Done."

# authorize keys
if [ "$nonroot" == "true" ] ; then
    sudo -u $saltuser salt-key -L
elif
    sudo salt-key -L
fi
