#!/bin/bash
set -ev

DIR=$PWD
CLEAN_ALL=$1

# Removes container
dockers=$(docker ps -a | grep "ica\|cli\|peer\|orderer" | awk '{print $1}')
if [[ $dockers ]]; then
  docker rm -f $dockers
fi

# Reset INTERMEDIATE_CA
if [ ! -z "$CLEAN_ALL" ]; then
  sudo rm -rf $DIR/crypto-config
  sudo rm -rf $DIR/ca-server-config
  mkdir -p $DIR/crypto-config $DIR/ca-server-config
  # cd $DIR/ca-server-config
  # sudo rm -rf $(ls | grep -v fabric-ca-server-config*)
  # cd $DIR
fi
