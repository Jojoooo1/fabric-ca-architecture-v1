#!/bin/bash
set -e

# import variable
. ./env.sh

# Remove ROOT_CA_CONFIG
rm -rf root-ca/*
rm -rf intermediate-ca/*
rm -rf ./openssl_*

echo "ROOT & INTERMEDIATE certificates were removed successfully"

# Remove FABRIC_CA_TLS
cd $FABRIC_CA_DIR

for i in ${!ORGANIZATION_NAME[@]}; do
  ORG_NAME=${ORGANIZATION_NAME[$i]}
  ORG_FABRIC_DIR=$FABRIC_CA_DIR/crypto-config/peerOrganizations/$ORG_NAME.$DOMAIN

  rm -rf $ORG_FABRIC_DIR/ca/*

  cd $ROOT_CA_DIR
  echo "FABRIC certificates were removed successfully from crypto-config folder"
done
