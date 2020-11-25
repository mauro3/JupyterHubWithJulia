#!/bin/bash
#
# These are the settings, which (may) need adjusting

## Seetings for Linode install

# leave this empty if you don't have a domain
export domain=

# this should be set to something irrespective
export hostname=

# leave empty if no https is required
export email4letsencrypt=

export fqdn=$hostname.$domain
export timezone="Europe/Zurich"


## For TLJH
export jupyteradmin=
export jupyteradmin_user=jupyter-$jupyteradmin
# how long a user's server stays alive without user interaction
export tljh_timeout=3600
# memory limit of each user
export tljh_limits_memory=1G
# CPU-core limit of each user
export tljh_limits_cpt=1
# set path to get python and julia of TLJH
# https://tljh.jupyter.org/en/latest/howto/env/user-environment.html#accessing-user-environment-outside-jupyterhub
export PATH=/opt/tljh/user/bin:${PATH}

## For Julia
export julia_global_env=/home/$jupyteradmin_user/julia-admin/environments/v1.4
# packages to be installed system-wide, separate entries with ":"
# (IJulia gets installed irrespective)
export julia_packages=
