#!/bin/bash
set -e

DIR=$PWD
CLEAN_ALL=$1 # Args used for cleaning all crypto related files

# Removes container
dockers=$(docker ps -a | grep "ica\|cli\|peer\|orderer" | awk '{print $1}')
if [[ $dockers ]]; then
  docker rm -f $dockers
fi

# Reset INTERMEDIATE_CA
if [ ! -z "$CLEAN_ALL" ]; then
  # Resets crypto-config
  sudo rm -rf $DIR/crypto-config/*
  # Resets ca-config
  sudo rm -rf $DIR/ca-config/*
  # Copy default config with backdate argument
  #  cp $DIR/fabric-ca-server-default-config-backdated.yaml $DIR/ca-config/fabric-ca-server-config.yaml # Same name or will create errors
  cp $DIR/fabric-ca-server-default-config-backdated.yaml $DIR/ca-config/fabric-ca-server-config.yaml # Same name or will create errors
  # if set specific ca-server-config
  # cd $DIR/ca-server-config
  # sudo rm -rf $(ls | grep -v fabric-ca-server-config*)
  # cd $DIR
fi

# Remove all volumes
docker volume prune
