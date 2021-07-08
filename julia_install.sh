#!/bin/bash
#
# Install the specified Julia version and packages, handling the environment
# as needed for TheLittlestJupyterHub

if [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` <julia_version> <julia_packages>"
  echo "Example: `basename $0` 1.6.1 Plots:StatsBase"
  exit 0
fi

# parse arguments
export julia_version=$1
export julia_packages=$2
export julia_version_short=$(grep -o '^[0-9]*\.[0-9]*' <<< $julia_version)

## Download and unpack Julia
export julia_archive_name="julia-$julia_version-linux-x86_64.tar.gz"
export julia_parent_dir="/opt/julia"
export julia_dir="$julia_parent_dir/$julia_version"
wget -O $julia_archive_name https://julialang-s3.julialang.org/bin/linux/x64/$julia_version_short/$julia_archive_name
mkdir -p julia-$julia_version
tar zxf $julia_archive_name julia-$julia_version
mkdir -p $julia_parent_dir
mv -f julia-$julia_version $julia_dir
# create symlinks
ln -sf $julia_dir/bin/julia /usr/local/bin/julia$julia_version
ln -sf $julia_dir/bin/julia /usr/local/bin/julia$julia_version_short
ln -sf $julia_dir/bin/julia /usr/local/bin/julia

## Install Julia packages
# This is the tricky bit and requires a bit of juggling with the DEPOT_PATH
# and different environments.

# the packages are installed into this depot:
export julia_global_depot=$(julia -e 'print(DEPOT_PATH[2])')
# (if not using this default, DEPOT_PATH will need to reflect this)
mkdir -p $julia_global_depot

# The corresponding environment is (another one could be chosen):
export julia_global_env_dir=$(julia -e 'using Pkg; print(Pkg.envdir(DEPOT_PATH[2]))')
export julia_global_env=$julia_global_env_dir/v$julia_version_short
mkdir -p $julia_global_env
touch $julia_global_env/Project.toml
# Note, this env needs to be made available to the user in startup.jl or by other means.
# --> see below

# Install IJulia
julia --project=$julia_global_env -e 'deleteat!(DEPOT_PATH, [1,3]); using Pkg; Pkg.update(); Pkg.add("IJulia"); Pkg.precompile()'
# and make the kernel available to TLJH
cp -r ~/.local/share/jupyter/kernels/julia-$julia_version_short /opt/tljh/user/share/jupyter/kernels/

# Install more packages
julia --project=$julia_global_env -e 'deleteat!(DEPOT_PATH, [1,3]); using Pkg; Pkg.update(); Pkg.precompile()'
if [ ! -z "$julia_packages" ]
then
    julia --project=$julia_global_env -e 'using Pkg; Pkg.add.(split(ENV["julia_packages"], '\'':'\'')); Pkg.precompile()'
fi

# ensure all users can read General registry
chmod -R a+rX $julia_global_depot/registries/General/

# The installed packages are availabe to all users now.
# But to avoid user-installs trying to write to the global Project.toml,
# give them their own Project.toml by adding it to /etc/skel.
export julia_local_env_dir=$(julia -e 'using Pkg; print(Pkg.envdir("/etc/skel/.julia/"))')
export julia_local_env=$julia_local_env_dir/v$julia_version_short
mkdir -p $julia_local_env
touch $julia_local_env/Project.toml
mkdir -p /etc/skel/.julia/config
echo "# Add load-path to globally installed packages" > /etc/skel/.julia/config/startup.jl
echo "push!(LOAD_PATH, "\"$julia_global_env\"")" >> /etc/skel/.julia/config/startup.jl
