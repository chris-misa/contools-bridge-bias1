#!/bin/bash

#
# Install / build / configure for overheads ping performance test
#
# Might need to be run under sudo
#

# Get dependencies for host system from deb
apt-get update
apt-get install -y libcap-dev libidn2-0-dev nettle-dev
apt-get install -y docker.io tmux ndppd

# Pull needed containers from docker hub
docker pull chrismisa/contools:ping
docker pull docker:stable-dind

# Download and make iputils (which contains our version of ping)
git clone https://github.com/iputils/iputils.git
pushd iputils
make
popd

# Move in config files for dockerd and ndppd
cp config/daemon.json /etc/docker/
cp config/ndppd.conf /etc/

# Restart both dockerd and ndppd to load configs
kill `ps -e | grep dockerd | sed -E 's/ *([0-9]+).*/\1/'`
kill `ps -e | grep ndppd | sed -E 's/ *([0-9]+).*/\1/'`
dockerd &
ndppd &

# The above invocations might not work: in the past we just used windows in tmux
# and ran both daemons in the forground.
