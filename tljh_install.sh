#!/bin/bash
#
# Installs The Littelest JupyterHub.
#
# Exectue as root at the ssh-shell

## Load variable
. ./settings_linode_tljh_julia.sh

## Install TLJH
# https://tljh.jupyter.org/en/latest/install/custom-server.html
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
# timeout after which server shuts down
# https://tljh.jupyter.org/en/latest/topic/idle-culler.html?highlight=timeout
tljh-config set services.cull.timeout $tljh_timeout
# Limit CPU & RAM
# https://tljh.jupyter.org/en/latest/topic/tljh-config.html?highlight=environment#user-server-limits
#+begin_src
tljh-config set limits.memory $tljh_limits_memory
tljh-config set limits.cpu $tljh_limits_cpu
tljh-config reload

echo "Now is probably a good time to make a backup of the server so it can be reverted to this state."
