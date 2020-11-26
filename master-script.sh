#!/bin/bash
# Master script.

## Settings
# Edit settings_linode_tljh_julia_TEMPLATE.sh and save as settings_linode_tljh_julia.sh

# make sure settings file is there
if [ ! -f "settings_linode_tljh_julia.sh" ]; then
    echo "settings_linode_tljh_julia.sh does not exist! Exiting..."
    exit 1
fi
# get settings
. ./settings_linode_tljh_julia.sh

# Finishes the server install
./linode_install.sh
# Does the TLJH install
./tljh_install.sh
# Installs packages, in particular IJulia to provide the Julia kernel
./tljh_package_installs.sh
