#!/bin/bash
set -e

# Organisations variables
DOMAIN=logistic
ORGANIZATION_NAME=(shipper)
ORGANIZATION_PEER_NUMBER=(2)

# Directories variables
ROOT_CA_DIR=$PWD
FABRIC_CA_DIR=$PWD/../../network # Fabric CA is created as intermediate CA

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

    ORG_RCA_DIR=root-ca/rca-$ORG_NAME

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
      -out $ORG_RCA_DIR/private/rca.$ORG_FULL_NAME.key.pem
    # ROOT_CA self-sign his own Certificate Signing Request
    openssl req -config openssl_root.cnf -new -x509 -sha256 -extensions v3_ca \
      -key $ORG_RCA_DIR/private/rca.$ORG_FULL_NAME.key.pem \
      -out $ORG_RCA_DIR/certs/rca.$ORG_FULL_NAME.crt.pem -days 3650 \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=rca.$ORG_FULL_NAME"

    sed -i -e "s#$ORG_RCA_DIR#DIR_NAME#" -e "#$ORG_FULL_NAME#ORG_NAME#" openssl_root.cnf

  done
  echo "******************************"
  echo
}

########################
### Creating INTERMEDIATE_CA ###
########################

createIntermediateCAPrivateKeyAndCSR() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo
    echo "Creating FABRIC_CA private key and CSR for $ORG_NAME"
    echo

    ORG_FULL_NAME=$ORG_NAME.$DOMAIN
    ORG_RCA_DIR="root-ca/rca-$ORG_NAME"
    ORG_ICA_DIR="intermediate-ca/ica-$ORG_NAME"

    #  # Replace Org directory & Org name
    sed -i -e "s#DIR_NAME#$ORG_RCA_DIR#" -e "s#ORG_NAME#$ORG_FULL_NAME#" openssl_root.cnf

    # Creating FABRIC_CA_SERVER crypto-config
    mkdir -p $ORG_ICA_DIR

    # Generate private key
    openssl ecparam -name prime256v1 -genkey -noout \
      -out $ORG_ICA_DIR/ica.$ORG_FULL_NAME.key.pem

    # INTERMEDIATE_CA self-sign his own Certificate Signing Request
    openssl req -new -sha256 \
      -key $ORG_ICA_DIR/ica.$ORG_FULL_NAME.key.pem \
      -out $ORG_ICA_DIR/ica.$ORG_FULL_NAME.csr \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=ica.$ORG_FULL_NAME"

    # ROOT_CA signs INTERMEDIATE_CA's Certificate Signing Request
    openssl ca -batch -config openssl_root.cnf -extensions v3_intermediate_ca -days 1825 -notext -md sha256 \
      -in $ORG_ICA_DIR/ica.$ORG_FULL_NAME.csr \
      -out $ORG_ICA_DIR/ica.$ORG_FULL_NAME.crt.pem

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

    cat $ORG_ICA_DIR/ica.$ORG_FULL_NAME.crt.pem $ORG_RCA_DIR/certs/rca.$ORG_FULL_NAME.crt.pem >$ORG_ICA_DIR/chain.$ORG_FULL_NAME.crt.pem
  done
  echo "******************************"
  echo
}

##########################
### Creating FABRIC_CA ###
##########################

createFabricFolderStructure() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Creating Fabric network crypto-config folder structure for $ORG_NAME"

    # Orgs directory
    ORG_DIR=$FABRIC_CA_DIR/crypto-config/peerOrganizations/$ORG_NAME.$DOMAIN

    # Creates Peer's org MSP directory
    for j in 1 ${ORGANIZATION_PEER_NUMBER[$i]}; do
      PEER_DIR=$ORG_DIR/peers/peer$(($j - 1)).$ORG_NAME.$DOMAIN # Peer name start at 0
      mkdir -p $PEER_DIR/msp/admincerts                         # Other directory will be created by fabric-ca-client
      # $PEER_DIR/msp/intermediatecerts will be automatically created
    done

    # Users
    REGISTRAR_DIR=$ORG_DIR/users/admin # default identity used at fabric-ca-server instantiation # Will register the others identities
    ADMIN_DIR=$ORG_DIR/users/Admin@$ORG_NAME.$DOMAIN/msp/admincerts
    mkdir -p $REGISTRAR_DIR $ADMIN_DIR

    # CA & MSP
    mkdir -p $ORG_DIR/ca $ORG_DIR/msp/admincerts $ORG_DIR/msp/cacerts $ORG_DIR/msp/intermediatecerts # Peers intermediatecerts will be automatically created

  done
  echo "******************************"
  echo
}

copyFilesToFabricCryptoConfig() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Copying FABRIC_CA Certificate to network folder for $ORG_NAME"

    ORG_ICA_DIR="intermediate-ca/ica-$ORG_NAME"
    ORG_DIR=$FABRIC_CA_DIR/crypto-config/peerOrganizations/$ORG_NAME.$DOMAIN
    cp $ORG_ICA_DIR/* $ORG_DIR/ca/
  done
  echo "******************************"
  echo
}

createRootCAStructure
createRootCAPrivateKeyAndCSR
createFabricFolderStructure
createIntermediateCAPrivateKeyAndCSR
createIntermediateCAChain
copyFilesToFabricCryptoConfig
