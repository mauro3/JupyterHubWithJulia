#!/bin/bash
#
# This continues TLJH install after tljh_install.sh.  This is executed at the
# web-terminal, or (maybe) by setting the path
# https://tljh.jupyter.org/en/latest/howto/env/user-environment.html#accessing-user-environment-outside-jupyterhub
# But I'm not sure about this.
#
# At the web-site, login there with $jupyteradmin name.
#
# You may want to backup the server now, as this is the trickier part,
# of which I'm not 100% sure.

. ./settings_linode_tljh_julia.sh

if [ $USER!=$jupyteradmin_user ]; then
    echo Execute this script as user $jupyteradmin_user
    exit 1
fi

## Install python packages (that's easy)
sudo -E pip install numpy
sudo -E pip install matplotlib
sudo -E pip install scipy

## Install Julia via conda
sudo -E conda install -y -c rmg julia

## Install Julia packages
export julia_global_depot=$(julia -e 'print(DEPOT_PATH[2])')
# (if not using this default, DEPOT_PATH will need to reflect this)

# make special project for global install (i.e. Project.toml and Manifest.toml)
sudo -E mkdir -p $julia_global_env
sudo -E touch $julia_global_env/Project.toml
# the packages are installed into this depot:
sudo -E mkdir -p $julia_global_depot

# Install IJulia
sudo -E julia --project=$julia_global_env -e 'deleteat!(DEPOT_PATH, [1,3]); using Pkg; Pkg.update(); Pkg.add("IJulia"); Pkg.precompile()'
# and make it available to TLJH
sudo -E cp -r ~/.local/share/jupyter/kernels/julia-* /opt/tljh/user/share/jupyter/kernels
sudo -E chmod -R +rx $julia_global_depot # TODO: this make the global depot not updatable!
sudo -E chmod -R +rx /opt/tljh/user/share/jupyter/kernels

# Install more packages
sudo -E julia --project=$julia_global_env -e 'deleteat!(DEPOT_PATH, [1,3]); using Pkg; Pkg.update(); Pkg.add.(split(ENV["julia_packages"], '\'':'\'')); Pkg.precompile()'

sudo -E julia --project=$julia_global_env -e '@show split(ENV["julia_packages"], ':')'
sudo -E julia --project=$julia_global_env -E 'split(ENV["julia_packages"], '\'':'\'')'
# Make them available to all jupyter users using the next script:
# tljh_user_setup.sh
# but before
echo "Now create your users using the web-control panel"
