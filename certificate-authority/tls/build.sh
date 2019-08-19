#!/bin/bash
set -e

# import variable
. ./env.sh

if [ ! -d $FABRIC_CA_DIR ]; then
  echo "Build failed, Fabric network directory not found"
  exit 1
fi

########################
### Creating ROOT_CA ###
########################

createRootCAStructure() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Creating ROOT_CA artifacts for $ORG_NAME"

    ORG_RCA_DIR="root-ca/rca-$ORG_NAME"

    # Creates roots & intermediate directory
    mkdir -p $ORG_RCA_DIR/private $ORG_RCA_DIR/certs $ORG_RCA_DIR/newcerts $ORG_RCA_DIR/crl
    chmod 700 $ORG_RCA_DIR/private
    # Creates CA artifacts
    touch $ORG_RCA_DIR/index.txt $ORG_RCA_DIR/serial

    #touch $ORG_RCA_DIR/crl/index.txt $ORG_RCA_DIR/crl/serial

    # Creates serial number, mandatory for openssl ca config
    echo 1000 >$ORG_RCA_DIR/serial
    #echo 00 >$ORG_RCA_DIR/serial

  done
  echo "******************************"
  echo
}

createRootCAPrivateKeyAndCSR() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Creating ROOT_CA private key and CSR for $ORG_NAME"

    ORG_FULL_NAME=$ORG_NAME.$DOMAIN
    ORG_RCA_DIR="root-ca/rca-$ORG_NAME"

    # Replace Org directory & Org name
    sed -i -e "s#DIR_NAME#$ORG_RCA_DIR#" -e "#ORG_NAME#$ORG_FULL_NAME#" openssl_root.cnf

    # Generate private key
    openssl ecparam -name prime256v1 -genkey -noout \
      -out $ORG_RCA_DIR/private/tls-rca.$ORG_FULL_NAME.key.pem

    # ROOT_CA self-sign his own Certiftls-icate Signing Request
    openssl req -config openssl_root.cnf -new -x509 -sha256 -extensions v3_ca \
      -key $ORG_RCA_DIR/private/tls-rca.$ORG_FULL_NAME.key.pem \
      -out $ORG_RCA_DIR/certs/tls-rca.$ORG_FULL_NAME.crt.pem -days 3650 \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=tls-rca.$ORG_FULL_NAME"

    sed -i -e "s#$ORG_RCA_DIR#DIR_NAME#" -e "#$ORG_FULL_NAME#ORG_NAME#" openssl_root.cnf

  done
  echo "******************************"
  echo
}

##########################
### Creating INTERMEDIATE_CA ###
##########################

createIntermediateCAStructure() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo
    echo "Creating INTERMEDIATE_CA artifacts for $ORG_NAME"
    echo

    ORG_ICA_DIR="intermediate-ca/ica-$ORG_NAME"

    # Creates roots & intermediate directory
    mkdir -p $ORG_ICA_DIR/private $ORG_ICA_DIR/certs $ORG_ICA_DIR/newcerts $ORG_ICA_DIR/crl
    chmod 700 $ORG_ICA_DIR/private
    # Creates CA artifacts
    touch $ORG_ICA_DIR/index.txt $ORG_ICA_DIR/serial

    #touch $ORG_ICA_DIR/crl/index.txt $ORG_ICA_DIR/crl/serial

    # Creates serial number, mandatory for openssl ca config
    echo 1000 >$ORG_ICA_DIR/serial
    #echo 00 >$ORG_ICA_DIR/serial

  done
  echo "******************************"
  echo
}

createIntermediateCAPrivateKeyAndCSR() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo
    echo "Creating INTERMEDIATE_CA private key and CSR for $ORG_NAME"
    echo

    ORG_FULL_NAME=$ORG_NAME.$DOMAIN
    ORG_RCA_DIR="root-ca/rca-$ORG_NAME"
    ORG_ICA_DIR="intermediate-ca/ica-$ORG_NAME"

    #  Replace Org directory & Org name
    sed -i -e "s#DIR_NAME#$ORG_RCA_DIR#" -e "s#ORG_NAME#$ORG_FULL_NAME#" openssl_root.cnf

    # Generate private key
    openssl ecparam -name prime256v1 -genkey -noout \
      -out $ORG_ICA_DIR/private/tls-ica.$ORG_FULL_NAME.key.pem

    # INTERMEDIATE_CA self-sign his own Certificate Signing Request
    openssl req -new -sha256 \
      -key $ORG_ICA_DIR/private/tls-ica.$ORG_FULL_NAME.key.pem \
      -out $ORG_ICA_DIR/certs/tls-ica.$ORG_FULL_NAME.csr -days 3650 \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=tls-ica.$ORG_FULL_NAME"

    # ROOT_CA signs INTERMEDIATE_CA's Certificate Signing Request
    openssl ca -batch -config openssl_root.cnf -extensions v3_intermediate_ca -days 1825 -notext -md sha256 \
      -in $ORG_ICA_DIR/certs/tls-ica.$ORG_FULL_NAME.csr \
      -out $ORG_ICA_DIR/certs/tls-ica.$ORG_FULL_NAME.crt.pem

    sed -i -e "s#$ORG_RCA_DIR#DIR_NAME#" -e "s#$ORG_FULL_NAME#ORG_NAME#" openssl_root.cnf

  done
  echo "******************************"
  echo
}

createIntermediateCAChain() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Creating FABRIC_CA chainfile certificate for $ORG_NAME"

    ORG_FULL_NAME=$ORG_NAME.$DOMAIN
    ORG_RCA_DIR="root-ca/rca-$ORG_NAME"
    ORG_ICA_DIR="intermediate-ca/ica-$ORG_NAME"

    cat $ORG_ICA_DIR/certs/tls-ica.$ORG_FULL_NAME.crt.pem $ORG_RCA_DIR/certs/tls-rca.$ORG_FULL_NAME.crt.pem >$ORG_ICA_DIR/tls-chain.$ORG_FULL_NAME.crt.pem
  done
  echo "******************************"
  echo
}

##########################
### Creating FABRIC_CERT ###
##########################

generateIntermediateCAIdentity() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo
    echo "Creating FABRIC_IDENTITY private key and CSR for $ORG_NAME"
    echo

    ORG_FULL_NAME=$ORG_NAME.$DOMAIN
    ORG_ICA_DIR="intermediate-ca/ica-$ORG_NAME"

    #  Replace Org directory & Org name
    sed -i -e "s#DIR_NAME#$ORG_ICA_DIR#" -e "s#ORG_NAME#$ORG_FULL_NAME#" openssl_intermediate.cnf

    # Creating FABRIC_CA_SERVER crypto-config
    ORG_ICA_IDENTITY_DIR="intermediate-ca/ica-$ORG_NAME-identity"

    # Creates Private Key
    for ((j = 0; j < ${ORGANIZATION_PEER_NUMBER[$i]}; j++)); do # loop every peer
      PEER_NAME="peer$j.$ORG_FULL_NAME"
      PEER_DIR="$ORG_ICA_IDENTITY_DIR/$PEER_NAME" # Peer name start at 0
      mkdir -p $PEER_DIR

      # Creates private key
      openssl ecparam -name prime256v1 -genkey -noout \
        -out $PEER_DIR/client.key

      # Self-sign Certificate
      openssl req -new -sha256 \
        -key $PEER_DIR/client.key \
        -out $PEER_DIR/client.csr \
        -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=$PEER_NAME"

      # INTERMEDIATE_CA sign Self-sign Certificate
      openssl ca -batch -config openssl_intermediate.cnf -extensions v3_intermediate_ca -days 1825 -notext -md sha256 \
        -in $PEER_DIR/client.csr \
        -out $PEER_DIR/client.crt

    done

    ORG_IDENTITY=ORGANIZATION_USERS_$ORG_NAME[@]
    for j in ${!ORG_IDENTITY}; do
      IDENTITY_NAME=$j
      IDENTITY_DIR=$ORG_ICA_IDENTITY_DIR/$IDENTITY_NAME # Peer name start at 0
      mkdir -p $IDENTITY_DIR                            # Other directory will be created by fabric-ca-client

      # Creates private key
      openssl ecparam -name prime256v1 -genkey -noout \
        -out $IDENTITY_DIR/client.key

      # Self-sign Certificate
      openssl req -new -sha256 \
        -key $IDENTITY_DIR/client.key \
        -out $IDENTITY_DIR/client.csr \
        -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=$IDENTITY_NAME"

      # INTERMEDIATE_CA sign Self-sign Certificate
      openssl ca -batch -config openssl_intermediate.cnf -extensions v3_intermediate_ca -days 1825 -notext -md sha256 \
        -in $IDENTITY_DIR/client.csr \
        -out $IDENTITY_DIR/client.crt
    done

    # Copy ICA certificate into identity folder
    cp $ORG_ICA_DIR/certs/tls-ica.$ORG_FULL_NAME.crt.pem $ORG_ICA_IDENTITY_DIR/ca.crt

    sed -i -e "s#$ORG_ICA_DIR#DIR_NAME#" -e "s#$ORG_FULL_NAME#ORG_NAME#" openssl_intermediate.cnf

  done
  echo "******************************"
  echo
}

##########################
### Creating FABRIC_FOLDER ###
##########################

createFabricFolderStructure() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Creating Fabric network crypto-config folder structure for $ORG_NAME"

    # Orgs directory
    ORG_FULL_NAME=$ORG_NAME.$DOMAIN
    ORG_FABRIC_DIR="$FABRIC_CA_DIR/crypto-config/peerOrganizations/$ORG_FULL_NAME"

    # Creates TLS for Peers & User & Orgs
    for ((j = 0; j < ${ORGANIZATION_PEER_NUMBER[$i]}; j++)); do # loop every peer
      PEER_NAME="peer$j.$ORG_FULL_NAME"
      PEER_DIR="$ORG_FABRIC_DIR/peers/$PEER_NAME"         # Peer name start at 0
      mkdir -p "$PEER_DIR/msp/tlscacerts" "$PEER_DIR/tls" # Other directory will be created by fabric-ca-client
    done

    ORG_IDENTITY=ORGANIZATION_USERS_$ORG_NAME[@]
    for j in ${!ORG_IDENTITY}; do
      IDENTITY_NAME=$j
      IDENTITY_DIR=$ORG_FABRIC_DIR/users/$IDENTITY_NAME
      mkdir -p "$IDENTITY_DIR/msp/tlscacerts" -p "$IDENTITY_DIR/tls"
    done

    # ORG TLSCA & MSP
    # mkdir -p $ORG_FABRIC_DIR/tlsca
    mkdir -p $ORG_FABRIC_DIR/msp/tlscacerts # $ORG_FABRIC_DIR/msp/tlsintermediatecerts

  done

  echo "******************************"
  echo
}

copyFilesToFabricNetwork() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Copying FABRIC_CA Certificate to network folder for $ORG_NAME"

    ORG_FULL_NAME=$ORG_NAME.$DOMAIN

    ORG_ICA_IDENTITY_DIR="intermediate-ca/ica-$ORG_NAME-identity"
    ORG_FABRIC_DIR="$FABRIC_CA_DIR/crypto-config/peerOrganizations/$ORG_FULL_NAME"

    # Copy in Org MSP
    cp $ORG_ICA_IDENTITY_DIR/ca.crt $ORG_FABRIC_DIR/msp/tlscacerts/tlsca.$ORG_FULL_NAME-cert.pem

    # Copy TLS for PEERS
    for ((j = 0; j < ${ORGANIZATION_PEER_NUMBER[$i]}; j++)); do # loop every peer
      IDENTITY_NAME="peer$j.$ORG_FULL_NAME"
      # Copy ICA certificate
      cp $ORG_ICA_IDENTITY_DIR/ca.crt $ORG_FABRIC_DIR/peers/$IDENTITY_NAME/msp/tlscacerts/tlsca.$ORG_FULL_NAME-cert.pem
      cp $ORG_ICA_IDENTITY_DIR/ca.crt $ORG_FABRIC_DIR/peers/$IDENTITY_NAME/tls/ca.crt
      # Copy PEERS certificate
      cp $ORG_ICA_IDENTITY_DIR/$IDENTITY_NAME/client.crt $ORG_FABRIC_DIR/peers/$IDENTITY_NAME/tls/
      cp $ORG_ICA_IDENTITY_DIR/$IDENTITY_NAME/client.key $ORG_FABRIC_DIR/peers/$IDENTITY_NAME/tls/
    done

    # Copy TLS for USERS
    ORG_IDENTITY=ORGANIZATION_USERS_$ORG_NAME[@]
    for j in ${!ORG_IDENTITY}; do
      IDENTITY_NAME=$j
      # Copy ICA certificate
      cp $ORG_ICA_IDENTITY_DIR/ca.crt $ORG_FABRIC_DIR/users/$IDENTITY_NAME/msp/tlscacerts/tlsca.$ORG_FULL_NAME-cert.pem
      cp $ORG_ICA_IDENTITY_DIR/ca.crt $ORG_FABRIC_DIR/users/$IDENTITY_NAME/tls/ca.crt
      # Copy Users certificate
      cp $ORG_ICA_IDENTITY_DIR/$IDENTITY_NAME/client.crt $ORG_FABRIC_DIR/users/$IDENTITY_NAME/tls
      cp $ORG_ICA_IDENTITY_DIR/$IDENTITY_NAME/client.key $ORG_FABRIC_DIR/users/$IDENTITY_NAME/tls
    done

  done

  echo "******************************"
  echo
}

# shipper.logistic/users/Admin@shipper.logistic/msp/tlscacerts/tlsca.shipper.logistic-cert.pem
# shipper.logistic/users/Admin@shipper.logistic/tls/ca.crt
# shipper.logistic/users/Admin@shipper.logistic/tls/client.crt
# shipper.logistic/users/Admin@shipper.logistic/tls/key.crt

# shipper.logistic/peers/peer0.shipper.logistic/msp/tlscacerts/tlsca.shipper.logistic-cert.pem
# shipper.logistic/users/peer0.shipper.logistic/tls/ca.crt
# shipper.logistic/users/peer0.shipper.logistic/tls/client.crt
# shipper.logistic/users/peer0.shipper.logistic/tls/key.crt

createRootCAStructure
createRootCAPrivateKeyAndCSR

createIntermediateCAStructure
createIntermediateCAPrivateKeyAndCSR
createIntermediateCAChain

generateIntermediateCAIdentity

createFabricFolderStructure
copyFilesToFabricNetwork
