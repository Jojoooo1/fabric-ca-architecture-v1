#!/bin/bash
set -e

# import variable
. ./env.sh

ROOT_CA_DIR=$PWD
FABRIC_CA_DIR=$PWD/../../network # Fabric CA is created as intermediate CA

# Remove ROOT_CA_CONFIG
rm -rf root-ca/*
rm -rf intermediate-ca/*

echo "TLS certificates were removed successfully"

# Remove FABRIC_CA_TLS
cd $FABRIC_CA_DIR

for i in ${!ORGANIZATION_NAME[@]}; do
  ORG_NAME=${ORGANIZATION_NAME[$i]}
  ORG_FULL_NAME=$ORG_NAME.$DOMAIN

  ORG_FABRIC_DIR="$FABRIC_CA_DIR/crypto-config/peerOrganizations/$ORG_FULL_NAME"

  # Remove TLS in Org MSP
  rm $ORG_FABRIC_DIR/msp/tlscacerts/tlsca.$ORG_FULL_NAME-cert.pem

  # Remove TLS for PEERS
  for ((j = 0; j < ${ORGANIZATION_PEER_NUMBER[$i]}; j++)); do # loop every peer
    IDENTITY_NAME="peer$j.$ORG_FULL_NAME"
    rm $ORG_FABRIC_DIR/peers/$IDENTITY_NAME/msp/tlscacerts/tlsca.$ORG_FULL_NAME-cert.pem
    rm $ORG_FABRIC_DIR/peers/$IDENTITY_NAME/tls/*
  done

  # Remove TLS for USERS
  ORG_IDENTITY=ORGANIZATION_USERS_$ORG_NAME[@]
  for j in ${!ORG_IDENTITY}; do
    IDENTITY_NAME=$j
    rm $ORG_FABRIC_DIR/users/$IDENTITY_NAME/msp/tlscacerts/tlsca.$ORG_FULL_NAME-cert.pem
    rm $ORG_FABRIC_DIR/users/$IDENTITY_NAME/tls/*
  done

  cd $ROOT_CA_DIR
  echo "FABRIC_CA certificates were removed successfully from crypto-config folder"
done
