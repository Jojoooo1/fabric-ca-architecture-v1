#!/bin/bash

# $1 organization index | $2 peer number
setVariables() {
  # set -x

  ORGANIZATION_INDEX=$1
  PEER_NUMBER=$2

  ORG_NAME=${ORGANIZATION_NAME[$ORGANIZATION_INDEX]}
  ORG_FULL_NAME=$ORG_NAME.$ORGANIZATION_DOMAIN
  ORG_MSPID=${ORGANIZATION_MSPID[ORGANIZATION_INDEX]}

  # PEER_NUMBER ($2) start at 1 (because of loop value) but PEER_NAME at 0 => do a subtraction
  if [ -z "$PEER_NUMBER" ]; then PEER_NUMBER=0; fi

  PEER_PORT_INDEX=${ORGANIZATION_PEER_STARTING_PORT[$ORGANIZATION_INDEX]} # Gets starting port
  PEER_PORT=$(($PEER_PORT_INDEX + $PEER_NUMBER * 1000))                   # Calc starting port + peer number

  CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG_FULL_NAME/users/Admin@$ORG_FULL_NAME/msp
  CORE_PEER_ADDRESS=peer${PEER_NUMBER}.$ORG_FULL_NAME:$PEER_PORT
  CORE_PEER_LOCALMSPID=${ORG_MSPID^} # Capitalize
  CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG_FULL_NAME/peers/peer$PEER_NUMBER.$ORG_FULL_NAME/tls/ca.crt

  # set +x
}

loadCAPrivateKey() {
  for i in ${!ORGANIZATION_NAME[@]}; do # @ get all value of the array ${} exec the value ! represent the index
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=$ORG_NAME.$ORGANIZATION_DOMAIN
    export CA${i}_PRIVATE_KEY=$(ls crypto-config/peerOrganizations/${ORG_FULL_NAME}/ca/*_sk | xargs -n1 basename)
  done
}

createChannel() {
  if [ $CORE_PEER_TLS_ENABLED = true ]; then
    docker exec -it cli sh -c "\
    peer channel create -o ${ORDERER_DOMAIN}:7050 --tls --cafile $ORDERER_CA_PATH -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx  \
    "
  else
    docker exec -it cli sh -c "\
    peer channel create -o ${ORDERER_DOMAIN}:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx  \
    "
  fi
}

joinPeersTochannel() {
  for i in ${!ORGANIZATION_NAME[@]}; do # Loop every organization
    for ((j = 0; j < ${ORGANIZATION_PEER_NUMBER[$i]}; j++)); do # loop every peer
      setVariables $i $j
      docker exec -it \
        -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" \
        -e "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS" \
        -e "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID" \
        -e "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE" \
        cli sh -c "peer channel join -b ${CHANNEL_NAME}.block"
    done

  done
}

setAnchorPeers() {
  for i in ${!ORGANIZATION_NAME[@]}; do # Loop every organization

    if [ $CORE_PEER_TLS_ENABLED = true ]; then
      ANCHOR_COMMAND="peer channel update -o ${ORDERER_DOMAIN}:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA_PATH -f ./channel-artifacts/${ORGANIZATION_NAME[$i]}-anchors.tx "
    else
      ANCHOR_COMMAND="peer channel update -o ${ORDERER_DOMAIN}:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${ORGANIZATION_NAME[$i]}-anchors.tx"
    fi

    # Update channel with anchor peer0
    setVariables $i 0
    docker exec -it \
      -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" \
      -e "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS" \
      -e "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID" \
      -e "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE" \
      cli sh -c "$ANCHOR_COMMAND"

  done
}

# Install multiple chaincodes
installChaincodeToPeers() {
  for k in ${!CHAINCODE_NAME[@]}; do # Loop every chaincode
    for i in ${!ORGANIZATION_NAME[@]}; do # Loop every organization

      for ((j = 0; j < ${ORGANIZATION_PEER_NUMBER[$i]}; j++)); do # loop every peer
        setVariables $i $j
        docker exec -it \
          -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" \
          -e "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS" \
          -e "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID" \
          -e "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE" \
          cli sh -c "peer chaincode install -n ${CHAINCODE_NAME[$k]} -v 1.0 -p ${CHAINECODE_PATH}${CHAINCODE_NAME[$k]} -l $LANGUAGE"
      done

    done
  done
}

initializeChaincodeContainer() {
  for i in ${!CHAINCODE_NAME[@]}; do # Loop every chaincode

    # Instantiate chaincode in orgs sets in CLI environment
    if [ $CORE_PEER_TLS_ENABLED = true ]; then
      docker exec -it cli sh -c "peer chaincode instantiate \
      -o ${ORDERER_DOMAIN}:7050 --tls --cafile $ORDERER_CA_PATH \
      -C $CHANNEL_NAME -n ${CHAINCODE_NAME[$i]} -l $LANGUAGE -v 1.0 \
      -c '{\"Args\":[\"\"]}' \
      -P $CHAINCODE_POLICY \
      "
    else
      docker exec -it cli sh -c "peer chaincode instantiate \
      -o ${ORDERER_DOMAIN}:7050 \
      -C $CHANNEL_NAME -n ${CHAINCODE_NAME[$i]} -l $LANGUAGE -v 1.0 \
      -c '{\"Args\":[\"\"]}' \
      -P $CHAINCODE_POLICY \
      "
    fi

    sleep 4

    ORG_NAME=${ORGANIZATION_NAME[0]}
    ORG_PEER=${ORGANIZATION_PEER_NUMBER[0]}

    # Query other peer in orgs sets in CLI environment to start containter

    for ((j = 1; j < $ORG_PEER; j++)); do

      ORG_FULL_NAME=$ORG_NAME.$ORGANIZATION_DOMAIN
      PEER_NUMBER=$j
      PEER_PORT=$((7051 + 1000 * $PEER_NUMBER)) # instantiating peer port start at 7051

      docker exec -it cli sh -c "\
          CORE_PEER_ADDRESS=peer$PEER_NUMBER.$ORG_FULL_NAME:$PEER_PORT \
          CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG_FULL_NAME/peers/peer$(($j - 1)).$ORG_FULL_NAME/tls/ca.crt \
          peer chaincode query -C $CHANNEL_NAME -n ${CHAINCODE_NAME[$i]} -c '{\"Args\":[\"getDataById\", \"instantiate\"]}' \
          "
    done

  done

}

# TODO
# initializeChaincodeContainerWithPrivateCollection() {}

startChaincodeContainer() {
  # Remove 1st value because already instantiated in initializeChaincodeContainer()
  ORGANIZATIONS=("${ORGANIZATION_NAME[@]:1}")
  PEER_NUMBER=("${ORGANIZATION_PEER_NUMBER[@]:1}")

  for k in ${!CHAINCODE_NAME[@]}; do # Loop every chaincode
    for i in ${!ORGANIZATIONS[@]}; do #  Loop every organization

      ORGANIZATION_START_INDEX=$(($i + 1))
      ORG_PEER=${PEER_NUMBER[$i]}

      for ((j = 0; j < $(($ORG_PEER)); j++)); do # Need to put it in number, was creating problem

        setVariables $ORGANIZATION_START_INDEX $j
        docker exec -it \
          -e "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH" \
          -e "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS" \
          -e "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID" \
          -e "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE" \
          cli sh -c "peer chaincode query -C $CHANNEL_NAME -n ${CHAINCODE_NAME[$k]} -c '{\"Args\":[\"getDataById\", \"instantiate\"]}' && sleep 2"
      done

    done
  done
}
