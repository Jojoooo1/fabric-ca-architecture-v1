#!/bin/bash
set -ev

ROOT_CA_DIR=$PWD
INTERMEDIATE_FABRIC_CA_DIR=$PWD/../intermediate-ca

# Resets fabric-ca-server data
rm -rf rca-*
rm -rf $INTERMEDIATE_FABRIC_CA_DIR/crypto-config/*

# look for Hyperledger and dev-peers related containers
dockers=$(docker ps -a | grep "ica\|cli" | awk '{print $1}')
if [[ $dockers ]]; then
  docker rm -f $dockers
fi
