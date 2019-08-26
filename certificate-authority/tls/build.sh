#!/bin/bash
set -e

# import variable
. ./config/env.sh
. ./config/utils.sh

if [ ! -d $FABRIC_CA_DIR ]; then
  echo "Build failed, Fabric network directory not found"
  exit 1
fi

./reset.sh
# Copy default config
cp -r ./config/openssl_* ./

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
copyFilesToFabricFolder

# remove default config
rm -rf ./openssl_*
