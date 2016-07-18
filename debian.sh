#!/bin/sh -e
# config
saltuser="salt"
saltgroup="salt"

saltowneddirs="/etc/salt /var/cache/salt /var/log/salt /var/run/salt"

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
