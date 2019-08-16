#!/bin/bash
set -e

ROOT_CA_DIR=$PWD
FABRIC_CA_DIR=$PWD/../../network # Fabric CA is created as intermediate CA

# Remove ROOT_CA_CONFIG
rm -rf rca-*
rm -rf ica/*

# Remove FABRIC_CA_CONFIG
if [ -d $FABRIC_CA_DIR ]; then
  cd $FABRIC_CA_DIR
  ./reset.sh "CLEAN_ALL"
  cd $ROOT_CA_DIR
  echo "FABRIC_CA certificates were removed successfully from crypto-config folder"
fi

echo "ROOT_CA certificates were removed successfully"
