#!/bin/sh -e
# version info
version() {
    echo "0.0.1"
    exit 0
}

# debian.sh usage
usage() {
    echo "Usage: debian.sh [OPTIONS]"
    echo "Bootstrap a salt master on a Debian system."
    echo ""
    echo "Mandatory arguments to long options are mandatory for short options too."
    echo "-f, --force       don't nag"
    echo "-u, --user=USER   install as specific user"
    echo "    --help        display this help and exit"
    echo "    --version     show version information and exit"
    exit 0
}

# does a command exist?
command_exists() {
    type "$1" > /dev/null 2>&1
}

sudo_command_exists() {
    echo "Checking if command '$1' exists..."
    echo "FIXME: this function doesn't work and is ignored."
    # sudo sh -c 'type "$1"'
}

# ensure we can run certain commands as user
requiredcommands="echo command sudo getopts"
for command in $requiredcommands
do
    command_exists "$command" || (
        echo "user can't access required command: $command"
        exit;
    )
done

# nag for safety
if [ ("$1" != "-f" || getuid == "0") ]; then
    echo "This script runs commands using sudo. Use at your own peril."
    echo "To disable this prompt, use the -f option."
    echo ""
    while true; do
        read -p "Do you wish to run this SaltStack deployment script? [Y/N]: " answer
        case $answer in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Y/N?"
        esac
    done
fi

# ensure we can run certain commands as root
requiredrootcommands="rm cp chown useradd groupadd"
for command in $requiredrootcommands do
do
    sudo_command_exists "$command" || (
        echo "root user can't access required command: $command"
        exit;
    )
done

# default config
saltuser="salt"
saltgroup="salt"

# directories that should be owned by the salt user
saltowneddirs="/etc/salt /var/cache/salt /var/log/salt /var/run/salt"


# parse commandline options


# install salt
echo "Installing required packages..."
sudo apt-get install salt-master salt-minion
echo "Done."

# add users and groups
echo "Adding $saltgroup group..."
sudo groupadd -f "$saltgroup"
echo "Done."

echo "Adding ${saltuser} user..."
id -u $saltuser || sudo useradd -g "$saltgroup" "$saltuser"
echo "Done."

# take ownership of directories to be used by salt
echo "Taking ownership of salt directories..."
for directory in $saltowneddirs
do
    echo "$directory"
    sudo chown -R "$saltgroup" $directory
done
echo "Done."

# deploy salt settings
echo "Deploying salt config files"
sudo rm -f /etc/salt/master
sudo rm -f /etc/salt/minion

sudo cp master /etc/salt/
sudo chown salt:salt /etc/salt/master

sudo cp minion /etc/salt/
sudo chown salt:salt /etc/salt/minion
echo "Done."


