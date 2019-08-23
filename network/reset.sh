#!/bin/bash
set -e

. ./scripts/env_var.sh

DIR=$PWD
CLEAN_ALL=$1 # Args used for cleaning all crypto related files

# Removes container
dockers=$(docker ps -a | grep "ica\|cli\|peer\|orderer" | awk '{print $1}')
if [[ $dockers ]]; then
  docker rm -f $dockers
fi

# Reset INTERMEDIATE_CA

# Resets crypto-config
sudo rm -rf $DIR/crypto-config/*
sudo rm -rf $DIR/channel-artifacts/*

# Resets ca-config
sudo rm -rf $DIR/ca-config/*

# Copy default config with backdate argument
for i in ${!ORGANIZATION_NAME[@]}; do
  cp $DIR/default-config-ca-server/fabric-ca-server-${ORGANIZATION_NAME[$i],,}-config-backdated.yaml $DIR/ca-config/fabric-ca-server-${ORGANIZATION_NAME[$i],,}-config.yaml # Same name or will create errors
done

# Remove all volumes
docker volume prune
