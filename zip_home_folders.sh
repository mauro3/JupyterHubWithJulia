#!/bin/bash
#
# This zips the home of each user and puts a jupyter-user.zip in their home-folder
#
# TODO: think about scratch

cd /home
export users=jupyter-*

for user in $users
do
    sudo -u $user zip -r /tmp/$user.zip $user/
    sudo -u $user mv /tmp/$user.zip /home/$user/
done
