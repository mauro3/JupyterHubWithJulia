#!/bin/bash
#
# This copies (recursively) files/dirs to all users and to /etc/skel

mkdir /tmp/transfer
cp -r $1 /tmp/transfer
chmod -R a+rx /tmp/transfer/$1

cp -r $1 /etc/skel

cd /home
export users=jupyter-*

for user in $users
do
    sudo -u $user cp -r /tmp/transfer/$1 /home/$user/
done

rm -r /tmp/transfer
