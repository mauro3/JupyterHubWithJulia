#!/bin/bash
#
# This is to make the Julia packages available to each user
# This includes IJulia without which Julia-notebooks do not run.

. ./settings_linode_tljh_julia.sh

cd /home
export users=jupyter-*

for user in $users
do
    sudo -u $user mkdir -p /home/$user/.julia/environments/v1.4
    sudo -u $jupyteradmin_user mkdir /tmp/transfer
    sudo -u $jupyteradmin_user cp $julia_global_env/*  /tmp/transfer
    sudo -u $user cp /tmp/transfer/* /home/$user/.julia/environments/v1.4
    sudo -u $jupyteradmin_user rm -r /tmp/transfer
done
