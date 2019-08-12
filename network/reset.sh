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
  sudo rm -rf $DIR/crypto-config
  sudo rm -rf $DIR/ca-config
  mkdir -p $DIR/crypto-config $DIR/ca-config
  # if set specific ca-server-config
  # cd $DIR/ca-server-config
  # sudo rm -rf $(ls | grep -v fabric-ca-server-config*)
  # cd $DIR
fi
