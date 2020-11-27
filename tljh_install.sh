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

# IPv4 address of the server
ip4=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
# ip4=$(hostname -i | cut - -d" " -f2)

###############################
## Server (Linode) base install
###############################

## Update packages
apt update
apt upgrade -y

timedatectl set-timezone $timezone

## Networking
echo $hostname > /etc/hostname
hostname -F /etc/hostname
# This sets the Fully Qualified Domain Name
if [ ! -v $domain ]; then
    echo $ip4 $fqdn >> /etc/hosts
fi

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

## HTTPS setup with Let's encrypt (if $email4letsencrypt is not empty)
if [ ! -v $email4letsencrypt ]; then
    # https://tljh.jupyter.org/en/latest/howto/admin/https.html#howto-admin-https
    tljh-config set https.enabled true
    tljh-config set https.letsencrypt.email $email4letsencrypt
    tljh-config add-item https.letsencrypt.domains $fqdn
    # reload
    # tljh-config show # setting can be checked
    tljh-config reload proxy
fi

## TLJH config

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

## Install Julia via conda
# TODO: install Julia binaries instead
conda install -y -c rmg julia

## Install Julia packages
# This is the tricky bit and requires a bit of juggling with the DEPOT_PATH
# and different environments.

# the packages are installed into this depot:
export julia_global_depot=$(julia -e 'print(DEPOT_PATH[2])')
# (if not using this default, DEPOT_PATH will need to reflect this)
mkdir -p $julia_global_depot

# The corresponding environment is (another one could be chosen):
export julia_global_env=$julia_global_depot/environments/v1.4
mkdir -p $julia_global_env
touch $julia_global_env/Project.toml
# Note, this env needs to be made available to the user in startup.jl or by other means.
# --> see below

# Install IJulia
julia --project=$julia_global_env -e 'deleteat!(DEPOT_PATH, [1,3]); using Pkg; Pkg.update(); Pkg.add("IJulia"); Pkg.precompile()'
# and make the kernel available to TLJH
cp -r ~/.local/share/jupyter/kernels/julia-* /opt/tljh/user/share/jupyter/kernels

# Install more packages
julia --project=$julia_global_env -e 'deleteat!(DEPOT_PATH, [1,3]); using Pkg; Pkg.update(); Pkg.add.(split(ENV["julia_packages"], '\'':'\'')); Pkg.precompile()'

# The installed packages are availabe to all users now.
# But to avoid user-installs trying to write to the global Project.toml,
# give them their own Project.toml by adding it to /etc/skel.
mkdir -p /etc/skel/.julia/environments/v1.4
touch /etc/skel/.julia/environments/v1.4/Project.toml
mkdir -p /etc/skel/.julia/config
echo "# Add load-path to globally installed packages" > /etc/skel/.julia/config/startup.jl
echo "push!(LOAD_PATH, "\"$julia_global_env\"")" >> /etc/skel/.julia/config/startup.jl


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
