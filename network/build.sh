#!/bin/bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Exit on first error, print all commands.
set -e

# load variables
. scripts/env_var.sh

dir=$PWD
RESET_PKI=$1
CA_PRODUCTION_PATH=/home/jonathan/Bureau/Hyperledger-node/Projects/0.base/ca-production

# 1. Generate crypto-config Folder containing all CA, PEER, TLS, NETWORK ADMIN, certificate etc.
generateCert() {
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi

  mkdir -p $dir/crypto-config

  # rm -Rf crypto-config

  set -x
  cryptogen generate --config="$dir/crypto-config.yaml"
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
}

generateCertFromOpenSSL() {
  # Certificates
  PKI_CERTIFICATE_PATH=/home/jonathan/Bureau/Hyperledger-node/Projects/0.base/ca-production/certificate-authority/certificate/
  # TLS
  PKI_TLS_PATH=/home/jonathan/Bureau/Hyperledger-node/Projects/0.base/ca-production/certificate-authority/tls/

  if [ ! "$(ls -A $PKI_CERTIFICATE_PATH)" ] || [ ! "$(ls -A $PKI_TLS_PATH)" ]; then
    echo "Build failed, Please verify PKI infrastructure path"
    exit 1
  fi

  cd $PKI_CERTIFICATE_PATH && ./build.sh
  cd $PKI_TLS_PATH && ./build.sh

  cd $dir

  sleep 3
}

# 2. Create Genesis block with initial consortium definition and anchorPeers
generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  mkdir -p $dir/channel-artifacts

  # Create Genesis block defined by profile OrgsOrdererGenesis in configtx.yaml
  set -x
  configtxgen -profile OrgsOrdererGenesis -outputBlock $dir/channel-artifacts/genesis.block # -channelID $CHANNEL_NAME # can not add -channelID will "cause implicit policy evaluation failed - 0 sub-policies were satisfied"
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi

  # Create initial channel configuration defined by profile OrgsChannel in configtx.yaml
  set -x
  configtxgen -profile OrgsChannel -outputCreateChannelTx $dir/channel-artifacts/channel.tx -channelID $CHANNEL_NAME
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi
}

generateAnchorPeerConfiguration() {

  CORE_PEER_LOCALMSPID=${ORG_MSPID^^${ORG_MSPID:0:1}} # Capitalize

  # Create anchorPeer configuration defined in profile OneOrgChannel in configtx.yaml
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[i]}  # Capital
    ORG_NAME_CAPITALIZED=${ORG_NAME^} # Define with majuscula in configtx
    set -x
    configtxgen -profile OrgsChannel -outputAnchorPeersUpdate $dir/channel-artifacts/$ORG_NAME-anchors.tx -channelID $CHANNEL_NAME -asOrg $ORG_NAME_CAPITALIZED
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate $ORG_NAME Anchor peer configuration transaction..."
      exit 1
    fi
  done
}

if [ $RESET_PKI == "reset" ]; then
  cd $CA_PRODUCTION_PATH && ./reset.sh
  cd $dir
fi

generateCert
# generateCertFromOpenSSL
generateChannelArtifacts
generateAnchorPeerConfiguration

# cryptogen generate --config=./$CRYPTO_CONFIG
# configtxgen -profile OrdererGenesis -outputBlock ./channel-artifacts/genesis.block -channelID testchainid
# configtxgen -profile Channel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel
