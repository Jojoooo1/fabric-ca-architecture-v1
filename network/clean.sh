#!/bin/bash
set -e

dir=$PWD
CLEAN_ALL=$1 # Args used for cleaning all crypto related files

# Removes container
dockers=$(docker ps -a | grep "ica\|cli\|peer\|orderer" | awk '{print $1}')
if [[ $dockers ]]; then
  docker rm -f $dockers
fi

sudo rm -rf $dir/ca-config/*
cp $dir/fabric-ca-server-default-config-backdated.yaml $dir/ca-config/fabric-ca-server-config.yaml # Same name or will create errors

# Copy default config with backdate argument
# cp $dir/fabric-ca-server-default-config-backdated.yaml $dir/ca-config/fabric-ca-server-config.yaml # Same name or will create errors
# cp $dir/fabric-ca-server-default-config-backdated-tls.yaml $dir/ca-config/fabric-ca-server-config.yaml # Same name or will create errors
# if set specific ca-server-config

# Remove all volumes
docker volume prune
