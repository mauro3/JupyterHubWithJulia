#!/bin/bash
#
# This is to make the Julia packages available to each user
# This includes IJulia without which Julia-notebooks do not run.

## Settings
# make sure settings file is there
if [ ! -f "settings_linode_tljh_julia.sh" ]; then
    echo "settings_linode_tljh_julia.sh does not exist! Exiting..."
    exit 1
fi
# get settings
. ./settings_linode_tljh_julia.sh
