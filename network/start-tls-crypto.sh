#!/bin/bash
set -e

# import var & utils lib
. ./scripts/env_var.sh
. ./scripts/utils.sh

ORG_DOMAIN=logistic
ORG_NAME=shipper

ORG_DIR=$PWD/crypto-config/peerOrganizations/$ORG_NAME.$ORG_DOMAIN

REGISTRAR_DIR=$ORG_DIR/users/tlsca-admin # default identity used at fabric-ca-server instantiation # Will register the others identities
ADMIN_DIR=$ORG_DIR/users/Admin@$ORG_NAME.$ORG_DOMAIN
PEER_DIR=$ORG_DIR/peers/peer0.$ORG_NAME.$ORG_DOMAIN

if [ ! -d $ORG_DIR ] || [ ! -d $REGISTRAR_DIR ] || [ ! -d $ADMIN_DIR ] || [ ! -d $PEER_DIR ]; then
  echo "Build failed, Please build ROOT_CA artifacts first"
  exit 1
fi

docker-compose -f docker-compose-ca.yaml up -d ica.shipper.logistic

sleep 15 # wait for certificate to be Active

# export FABRIC_CA_CLIENT_TLS_CERTFILES=$ORG_DIR/peers/peer0.$ORG_NAME.$ORG_DOMAIN/tls/tls-ica.shipper.logistic.crt.pem
# export FABRIC_CA_CLIENT_HOME=$REGISTRAR_DIR

# No trusted root certificates for TLS were provided
# export FABRIC_CA_CLIENT_TLS_CERTFILES=/home/jonathan/Bureau/Hyperledger-node/Projects/0.base/ca-production/network/crypto-config/peerOrganizations/shipper.logistic/tlsca/tls-ica.shipper.logistic.crt.pem
# export FABRIC_CA_CLIENT_HOME=/home/jonathan/Bureau/Hyperledger-node/Projects/0.base/ca-production/network/crypto-config/peerOrganizations/shipper.logistic/users/tlsca-admin

# fabric-ca-client enroll -d -m tlsca-admin -u https://tlsca-admin:tlsca-adminpw@localhost:8054
# sleep 2
# fabric-ca-client register -d --id.name peer0.$ORG_NAME.$ORG_DOMAIN --id.secret mysecret --id.type peer -u https://localhost:8054

# # #####

# export FABRIC_CA_CLIENT_MSPDIR=tls
# # export FABRIC_CA_CLIENT_TLS_CERTFILES=$ORG_DIR/peers/peer0.$ORG_NAME.$ORG_DOMAIN/tls/tls-ica.shipper.logistic.crt.pem
# export FABRIC_CA_CLIENT_HOME=$PEER_DIR

# cp $ORG_DIR/tlsca/tls-ica.shipper.logistic.crt.pem $ORG_DIR/peers/peer0.$ORG_NAME.$ORG_DOMAIN/tls

# fabric-ca-client enroll \
#   --enrollment.profile tls \
#   --csr.hosts $ORG_DOMAIN  \
#   -m peer0.$ORG_NAME.$ORG_DOMAIN -u https://peer0.$ORG_NAME.$ORG_DOMAIN:mysecret@localhost:8054

# # --csr.names "C=BR,ST=Sao Paulo,L=Sao Paulo,O=org1.$ORG_DOMAIN" \
