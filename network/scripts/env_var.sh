export COMPOSE_PROJECT_NAME=net
export IMAGE_TAG=latest
export CORE_PEER_TLS_ENABLED=false
export CA_TLS_ENABLED=false

# ----------------------
COMPOSE_FILE_CLI=docker-compose-cli.yaml
COMPOSE_FILE_CA=docker-compose-ca.yaml
COMPOSE_FILE_RAFT=docker-compose-raft.yaml

LANGUAGE=node
VERSION=1.0.0
GO_PATH=/opt/gopath/src/
CHAINECODE_PATH="${GO_PATH}github.com/chaincode/" # defined in volume

CHANNEL_NAME=mychannel

export CHAINCODE_PATH="../chaincode"
CHAINCODE_NAME=('organizacao')
# CHAINCODE_NAME_WITH_PRIVATE_COLLECTION=()
CHAINCODE_POLICY=('"OR ('"'"'ShipperMSP.peer'"'"','"'"'TransporterMSP.peer'"'"')"')
# CHAINCODE_POLICY_PRIVATE_COLLECTION=()

DOMAIN=logistic
# ORGANIZATION_NAME=(Shipper Transporter)
ORGANIZATION_NAME=(Shipper)
ORGANIZATION_MSPID=(${ORGANIZATION_NAME[0]}MSP)
# ORGANIZATION_MSPID=(${ORGANIZATION_NAME[0]}MSP ${ORGANIZATION_NAME[1]}MSP ${ORGANIZATION_NAME[2]}MSP)
ORGANIZATION_DOMAIN=(${ORGANIZATION_NAME[0],,}.${DOMAIN}) # ORGANIZATION_NAME in minuscula
# ORGANIZATION_DOMAIN=(${ORGANIZATION_NAME[0],,}.${DOMAIN} ${ORGANIZATION_NAME[1],,}.${DOMAIN} ${ORGANIZATION_NAME[2],,}.${DOMAIN}) # ORGANIZATION_NAME in minuscula

ORGANIZATION_PEER_NUMBER=(2)           # Template count in crypto-config && modify docker-compose
ORGANIZATION_PEER_STARTING_PORT=(7051) # PORT START NUMBER

ORDERER_TYPE="raft"
ORDERER_NAME=Intelipost
ORDERER_DOMAIN=${ORDERER_NAME,,}.${DOMAIN} #ORDERER_NAME in minuscula
ORDERER_CA_PATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/${DOMAIN}/orderers/${ORDERER_DOMAIN}/msp/tlscacerts/tlsca.${DOMAIN}-cert.pem"
