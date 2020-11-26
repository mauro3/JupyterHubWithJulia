#!/bin/bash
#
# This is a linode.com StackScript to deploy a JupyterHub instance.  It's tested to run
# with Ubuntu 20.04 LTS.
#
# StackScripts doc:
# https://www.linode.com/docs/guides/platform/stackscripts/
# https://www.linode.com/docs/guides/how-to-deploy-a-new-linode-using-a-stackscript/
#
# Linode install:
# - https://www.linode.com/docs/guides/getting-started/
# - https://www.linode.com/docs/guides/securing-your-server/

## Settings
# make sure settings file is there
if [ ! -f "settings_linode_tljh_julia.sh" ]; then
    echo "settings_linode_tljh_julia.sh does not exist! Exiting..."
    exit 1
fi
# get settings
. ./settings_linode_tljh_julia.sh

# IPv4 address of the linode
ip4=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
# ip4=$(hostname -i | cut - -d" " -f2)

## Linode base install

# Update packages
apt update
apt upgrade -y

timedatectl set-timezone $timezone

# Networking
echo $hostname > /etc/hostname
hostname -F /etc/hostname
# This sets the Fully Qualified Domain Name
if [ ! -v $domain ]; then
    echo $ip4 $fqdn >> /etc/hosts
fi

# ssh
# disable password login
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
systemctl restart sshd

# Firewall
apt install ufw
ufw default allow outgoing
ufw default deny incoming
ufw limit ssh
ufw allow https
ufw allow http
# ufw enable
yes | ufw enable

## JupyterHub install
# follows
# https://tljh.jupyter.org/en/latest/install/custom-server.html
# Install dependencies, the rest is done with tljh_install.sh.
apt install python3 python3-dev git curl -y
