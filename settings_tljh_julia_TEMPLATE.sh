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
export tljh_limits_memory=2G
# CPU-core limit of each user
export tljh_limits_cpu=1
# set path to get python and julia of TLJH
# https://tljh.jupyter.org/en/latest/howto/env/user-environment.html#accessing-user-environment-outside-jupyterhub
export PATH=/opt/tljh/user/bin:${PATH}

## For Julia

# version of Julia to install. If set to the empty string, Julia will not be installed.
export julia_version="1.6.1"

# Packages to be installed system-wide, separate entries with ":"
# (IJulia gets installed irrespective)
export julia_packages=
