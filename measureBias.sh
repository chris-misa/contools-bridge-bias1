#!/bin/bash

#
# Experiment to compare a bias estimate from
# dind to actual observed bias.
#
# Updated to test different paths and
# to use measurement container as a service
# model rather then spinning containers
# from command line for each measurement.
#
# Run under sudo
#

# Address to ping to
export TARGET_IPV4="10.10.1.2"
export TARGET_IPV6="fd41:98cb:a6ff:5a6a::"

# Argument sequence is an associative array
# between file suffixes and argument strings
declare -A ARG_SEQ=(
  ["i0.5s16.ping"]="-c 3 -i 0.5 -s 16"
)

# Native (local) ping command
export NATIVE_PING_CMD="$(pwd)/iputils/ping"
export NATIVE_DEV="eno1d1"

# Info for docker in docker container
export DIND_IMAGE_NAME="docker:stable-dind"
export DIND_CONTAINER_NAME="docker-in-docker"
export DIND_IPV6_SUBNET="2601:1c0:cb03:1a9d:eeee::/80"

# Info for ping container
export PING_IMAGE_NAME="chrismisa/contools:ping"
export PING_CONTAINER_NAME="ping-container"

# Tag for data directory
export DATE_TAG=`date +%Y%m%d%H%M%S`
# File name for metadata
export META_DATA="Metadata"

# Sleep for putting time around measurment
export SLEEP_CMD="sleep 5"
# Cosmetics
export B="------------"

# Make a directory for results
# echo $B Gathering system metadata . . . $B
# mkdir $DATE_TAG
# cd $DATE_TAG
# 
# # Get some basic meta-data
# echo "uname -a -> $(uname -a)" >> $META_DATA
# echo "docker -v -> $(docker -v)" >> $META_DATA
# echo "sudo lshw -> $(sudo lshw)" >> $META_DATA

# Set up containers
echo $B Spinning up containers $B

# Spin up docker in docker container
docker run --rm --privileged -d \
  --name="$DIND_CONTAINER_NAME" \
  $DIND_IMAGE_NAME \
  --ipv6 --fixed-cidr-v6="$DIND_IPV6_SUBNET"

# Spin up ping container in native docker
docker run --rm -itd \
  --name="$PING_CONTAINER_NAME" \
  --entrypoint="/bin/bash" \
  $PING_IMAGE_NAME

# Wait for them to be ready
until [ "`docker inspect -f {{.State.Running}} $DIND_CONTAINER_NAME`" \
        == "true" ] && \
      [ "`docker inspect -f {{.State.Running}} $PING_CONTAINER_NAME`" \
        == "true" ]
do
  sleep 1
done

# Get docker in docker container's ip addresses
DIND_IPV4=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $DIND_CONTAINER_NAME`
DIND_IPV6=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.GlobalIPv6Address}}{{end}}' $DIND_CONTAINER_NAME`
echo "  docker in docker container up with"
echo "    ipv4: $DIND_IPV4"
echo "    ipv6: $DIND_IPV6"

# Get ping container's ip addresses
PING_IPV4=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $PING_CONTAINER_NAME`
PING_IPV6=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.GlobalIPv6Address}}{{end}}' $PING_CONTAINER_NAME`
echo "  ping container up with"
echo "    ipv4: $PING_IPV4"
echo "    ipv6: $PING_IPV6"


# Spin up ping container in docker in docker
docker exec $DIND_CONTAINER_NAME \
  docker run --rm -itd \
    --name="$PING_CONTAINER_NAME" \
    --entrypoint="/bin/bash" \
    $PING_IMAGE_NAME

# Wait for it to be ready
until [ "`docker exec $DIND_CONTAINER_NAME \
            docker inspect -f {{.State.Running}} $PING_CONTAINER_NAME`" \
        == "true" ]
do
  sleep 1
done

# Get ping container in docker in docker's ip addresses
DIND_PING_IPV4=`docker exec $DIND_CONTAINER_NAME \
  docker inspect \
  -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
  $PING_CONTAINER_NAME`
DIND_PING_IPV6=`docker exec $DIND_CONTAINER_NAME \
  docker inspect \
  -f '{{range .NetworkSettings.Networks}}{{.GlobalIPv6Address}}{{end}}' \
  $PING_CONTAINER_NAME`
echo "  ping container in docker in docker up with"
echo "    ipv4: $DIND_PING_IPV4"
echo "    ipv6: $DIND_PING_IPV6"

# take a break and see if this works. . .

# Run ipv4 measurements

# Run ipv6 measurements
