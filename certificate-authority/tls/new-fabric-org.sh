#!/bin/bash
set -e

# import variable
. ./config/utils.sh

DOMAIN=logistic

ORGANIZATION_NAME=("test")
ORGANIZATION_PEER_NUMBER=(2)
ORGANIZATION_ORDERER_NUMBER=(1)

ORGANIZATION_USERS_test=("admin" "Admin@test.$DOMAIN")

CA_PREFIX="tls-"
TLS_CA=true

# Directories variables
ROOT_CA_DIR=$PWD
FABRIC_CA_DIR=$ROOT_CA_DIR/../../network # Fabric CA is created as intermediate CA

# Config
rm -rf ./openssl_*
cp -r ./config/openssl_* ./

# if [ ! -d $FABRIC_CA_DIR ]; then
#   echo "Build failed, Fabric network directory not found"
#   exit 1
# fi

# Creates ROOT_CA
createRootCAStructure
createRootCA

# Creates INTERMEDIATE_CA
createIntermediateCAStructure
createIntermediateCA
createIntermediateCAChain

# Generates FABRIC_IDENTITY
generateIntermediateCAIdentityTLS

# Copies to FABRIC_NETWORK
# copyFilesToFabricFolder

# remove default config
rm -rf ./openssl_*
