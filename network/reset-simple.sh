#!/bin/bash
set -e

# Used only to clean crypto-config
ORGANIZATION_NAME=("shipper" "transporter" "insurance")

DIR=$PWD
CLEAN_ALL=$1 # Args used for cleaning all crypto related files

# Removes container
dockers=$(docker ps -a | grep "hyperledger\|dev-peer" | awk '{print $1}')
if [[ $dockers ]]; then
  docker rm -f $dockers
fi

# Resets ca-config
sudo rm -rf $DIR/ca-config/*

# Copy default config with backdate argument
for i in ${!ORGANIZATION_NAME[@]}; do
  CONFIG_FOLDER=$DIR/ca-config/fabric-ca-server-${ORGANIZATION_NAME[$i],,}
  # Mandatory specific folder to overwrite config
  mkdir -p $CONFIG_FOLDER
  cp $DIR/default-config-ca-server/fabric-ca-server-${ORGANIZATION_NAME[$i],,}-config-backdated.yaml $CONFIG_FOLDER/fabric-ca-server-config.yaml # Same name or will create errors
done

# Remove all volumes
docker volume prune
