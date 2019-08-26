#!/bin/bash

# Docker-compose configuration
export COMPOSE_PROJECT_NAME=net
export IMAGE_TAG=latest
export CORE_PEER_TLS_ENABLED=true
export CA_TLS_ENABLED=true
export CHAINCODE_PATH="../chaincode"

# Docker compose files
COMPOSE_FILE_CLI=docker-compose-cli.yaml
COMPOSE_FILE_CA=docker-compose-ca.yaml
COMPOSE_FILE_RAFT=docker-compose-raft.yaml

# Channel
CHANNEL_NAME=mychannel

# Chaincode configuration
LANGUAGE=node
VERSION=1.0.0
GO_PATH=/opt/gopath/src/
CHAINECODE_PATH="${GO_PATH}github.com/chaincode/" # defined in volume

# Chaincode parameters
CHAINCODE_NAME=('organizacao')
CHAINCODE_POLICY=('"OR ('"'"'ShipperMSP.peer'"'"','"'"'TransporterMSP.peer'"'"')"')

# Organization definition
ORGANIZATION_DOMAIN=logistic
ORGANIZATION_NAME=("shipper" "transporter")
ORGANIZATION_MSPID=("ShipperMSP" "TransporterMSP")

ORGANIZATION_PEER_NUMBER=(1 1)              # Template count in crypto-config && modify docker-compose
ORGANIZATION_PEER_STARTING_PORT=(7051 9051) # PORT START NUMBER if two peers 7051, 8051 next orgs start at 9051

# Orderer definition
ORDERER_NAME=intelipost
ORDERER_DOMAIN=$ORDERER_NAME.${ORGANIZATION_DOMAIN} #ORDERER_NAME in minuscula
ORDERER_CA_PATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/${ORGANIZATION_DOMAIN}/orderers/${ORDERER_DOMAIN}/msp/tlscacerts/tlsca.${ORGANIZATION_DOMAIN}-cert.pem"

# Certificate authority definition
ORGANIZATION_CA_URL=("localhost:7054" "localhost:8054" "localhost:9054")

# Organization User definition (only used if using RCA/ICA)
ORGANIZATION_USERS_shipper=("Admin@shipper.logistic")
ORGANIZATION_USERS_transporter=("Admin@transporter.logistic")
ORGANIZATION_USERS_insurance=("Admin@insurance.logistic")

# Folders
CONFIG_FOLDER=$PWD/crypto-config
