#!/bin/bash
#
# This installs The Littlest JupyterHub with a Julia Kernel on a Ubuntu server.
# (Tested on Linode.com with Ubuntu 20.04 LTS)
#
# Make sure to create a settings_tljh_julia.sh from
# settings_tljh_julia_TEMPLATE.sh?"

## Settings
# make sure settings file is there
if [ ! -f "settings_tljh_julia.sh" ]; then
    echo "settings_tljh_julia.sh does not exist!"
    echo "Did you edit and rename settings_tljh_julia_TEMPLATE.sh?"
    echo "Exiting..."
    exit 1
fi
# get settings
. ./settings_tljh_julia.sh

# # IPv4 address of the server
# ip4=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
# # ip4=$(hostname -i | cut - -d" " -f2)

###############################
## Server (Linode) base install
###############################

## Update packages
apt update
apt upgrade -y

timedatectl set-timezone $timezone

# ## Networking
# echo $hostname > /etc/hostname
# hostname -F /etc/hostname
# # This sets the Fully Qualified Domain Name
# if [ ! -v $domain ]; then
#     echo $ip4 $fqdn >> /etc/hosts
# fi

## SSH
# disable password login if there is a SSH key for login
if [ -f "/root/.ssh/authorized_keys" ]; then
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    systemctl restart sshd
fi

## Firewall
apt install ufw
ufw default allow outgoing
ufw default deny incoming
ufw limit ssh
ufw allow https
ufw allow http
# ufw enable
yes | ufw enable

##################################
## The Littlest JupyterHub install
##################################
# follows https://tljh.jupyter.org/en/latest/install/custom-server.html

## Install dependencies
apt install python3 python3-dev git curl -y

## Install TLJH
curl -L https://tljh.jupyter.org/bootstrap.py | python3 - --admin $jupyteradmin

## TLJH config
##############

## HTTPS setup
case $https_setup in

    none)
	echo "HTTPS: Not setting up HTTPS"
	;;

    self-cert)
	echo "HTPPS: Installing self-signed certificates"
	# this just uses default inputs for the key & value. If you want to set them use
	# a config file
	# https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html#CONFIGURATION-FILE-FORMAT
	openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out tljh.crt -keyout tljh.key -batch
	mv tljh.key tljh.crt /opt/tljh/state
	tljh-config set https.enabled true
	tljh-config set https.tls.key /opt/tljh/state/tljh.key
	tljh-config set https.tls.cert  /opt/tljh/state/tljh.crt
	tljh-config reload proxy
	;;

    existing-cert)
	echo "HTPPS: Installing existing certificates"
	cp $ssl_key $ssl_cert /opt/tljh/state
	tljh-config set https.enabled true
	tljh-config set https.tls.key /opt/tljh/state/$(basename $ssl_key)
	tljh-config set https.tls.cert  /opt/tljh/state/$(basename $ssl_cert)
	tljh-config reload proxy
	;;

    letsencrypt)
	if [ ! -v $email4letsencrypt ]; then
	    echo "HTPPS: Installing Let's Encrypt certificate"
	    # https://tljh.jupyter.org/en/latest/howto/admin/https.html#howto-admin-https
	    tljh-config set https.enabled true
	    tljh-config set https.letsencrypt.email $email4letsencrypt
	    tljh-config add-item https.letsencrypt.domains $fqdn
	    tljh-config reload proxy
	else
	    echo 'HTTPS: Option "https_setup=letsencrypt" but no value given for option "email4letsencrypt".  Lets Encrypt needs an email. Exiting...'
	    exit 1
	fi
	;;

    *)
	echo 'HTTPS: Option for "https_setup" not valid. Exiting'
	exit 1
	;;
esac
# run `tljh-config show` to check settings


## more TLJH config

# Set timeout after which server shuts down
# https://tljh.jupyter.org/en/latest/topic/idle-culler.html?highlight=timeout
tljh-config set services.cull.timeout $tljh_timeout
# Limit CPU & RAM
# https://tljh.jupyter.org/en/latest/topic/tljh-config.html?highlight=environment#user-server-limits
#+begin_src
tljh-config set limits.memory $tljh_limits_memory
tljh-config set limits.cpu $tljh_limits_cpu

tljh-config reload

#################################################
# Python and Julia package installs (system-wide)
#################################################
# Including installing the Julia Jupyter-kernel

## Install python packages (that's easy)
pip install numpy
pip install matplotlib
pip install scipy

./julia_install.sh $julia_version $julia_packages

##########
# All done
##########
echo "Install finished!"
echo "Have a look at the tljh_extras.sh scripts for extras."
echo " "
echo "Probably it is also the time for a reboot, as likely a new Linux-kernel was installed."
echo " "
echo "Then login with your admin account $jupyteradmin on $fqdn (or $ip4 if you have no url)."
echo "Create your users using the web-control panel."
