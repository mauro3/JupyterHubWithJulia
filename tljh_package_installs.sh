#!/bin/bash
#
# You may want to backup the server now, as this is the trickier part,
# of which I'm not 100% sure.
#
# You may want to execute this at the web-terminal, if so,
# pre-pend the commands with `sudo -E`.

## Settings
# make sure settings file is there
if [ ! -f "settings_linode_tljh_julia.sh" ]; then
    echo "settings_linode_tljh_julia.sh does not exist! Exiting..."
    exit 1
fi
# get settings
. ./settings_linode_tljh_julia.sh

## Install python packages (that's easy)
pip install numpy
pip install matplotlib
pip install scipy

## Install Julia via conda
# TODO: install binaries instead
conda install -y -c rmg julia

## Install Julia packages

# the packages are installed into this depot:
export julia_global_depot=$(julia -e 'print(DEPOT_PATH[2])')
# (if not using this default, DEPOT_PATH will need to reflect this)
mkdir -p $julia_global_depot

# the environment is this one
export julia_global_env=$julia_global_depot/environments/v1.4
# make this
mkdir -p $julia_global_env
touch $julia_global_env/Project.toml

# Install IJulia
julia --project=$julia_global_env -e 'deleteat!(DEPOT_PATH, [1,3]); using Pkg; Pkg.update(); Pkg.add("IJulia"); Pkg.precompile()'
# and make it available to TLJH
cp -r ~/.local/share/jupyter/kernels/julia-* /opt/tljh/user/share/jupyter/kernels

# Install more packages
julia --project=$julia_global_env -e 'deleteat!(DEPOT_PATH, [1,3]); using Pkg; Pkg.update(); Pkg.add.(split(ENV["julia_packages"], '\'':'\'')); Pkg.precompile()'

# The installed packages are availabe to all users now.
# But to avoid user-installs trying to write to the global Project.toml, give them their own Project.toml.
mkdir -p /etc/skel/.julia/environments/v1.4
touch /etc/skel/.julia/environments/v1.4/Project.toml
mkdir -p /etc/skel/.julia/config
echo "# Add load-path to globally installed packages" > /etc/skel/.julia/config/startup.jl
echo "push!(LOAD_PATH, "\"$julia_global_env\"")" >> /etc/skel/.julia/config/startup.jl

echo "Now create your users using the web-control panel"
