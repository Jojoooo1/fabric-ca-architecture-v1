#!/bin/bash
set -e

export FABRIC_CFG_PATH=${PWD}

DOMAIN=logistic
ORGANIZATION_NAME=(org1)

ROOT_CA_DIR=$PWD
INTERMEDIATE_FABRIC_CA_DIR=$PWD/../intermediate-ca

CreateFabricFolderStructure() {
  for i in ${!ORGANIZATION_NAME[@]}; do

    # Orgs directory
    ORG_DIR=$INTERMEDIATE_FABRIC_CA_DIR/crypto-config/peerOrganizations/${ORGANIZATION_NAME[$i]}.$DOMAIN
    # Peer directory
    PEER_DIR=$ORG_DIR/peers/peer0.${ORGANIZATION_NAME[$i]}.$DOMAIN

    # User directory
    REGISTRAR_DIR=$ORG_DIR/users/admin
    # Create admin
    ADMIN_DIR=$ORG_DIR/users/Admin@${ORGANIZATION_NAME[$i]}.$DOMAIN

    # Creates directories
    mkdir -p $ORG_DIR/ca $ORG_DIR/msp $PEER_DIR $REGISTRAR_DIR $ADMIN_DIR

  done
}

createRootCAStructure() {
  for i in ${!ORGANIZATION_NAME[@]}; do

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    # Creates roots directory
    mkdir -p rca-$ORG_NAME/private rca-$ORG_NAME/certs rca-$ORG_NAME/newcerts rca-$ORG_NAME/crl
    chmod 700 rca-$ORG_NAME/private
    # Creates CA artifacts
    touch rca-$ORG_NAME/index.txt rca-$ORG_NAME/serial

    #touch rca-$ORG_NAME/crl/index.txt rca-$ORG_NAME/crl/serial

    # Creates serial number, mandatory for openssl ca config
    echo 1000 >rca-$ORG_NAME/serial
    #echo 00 >rca-$ORG_NAME/serial

  done
}

CreateRootCAPrivateKeyAndCSR() {
  for i in ${!ORGANIZATION_NAME[@]}; do

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=${ORGANIZATION_NAME[$i]}.$DOMAIN
    CA_DIR=rca-${ORGANIZATION_NAME[$i]}

    # Replace Org directory & Org name
    sed -i "s/DIR_NAME/$CA_DIR/g" openssl_root.cnf
    sed -i "s/ORG_NAME/$ORG_FULL_NAME/g" openssl_root.cnf

    # Generate private key
    openssl ecparam -name prime256v1 -genkey -noout -out rca-$ORG_NAME/private/rca.$ORG_FULL_NAME.key.pem
    # ROOT_CA self-sign his own Certificate Signing Request
    openssl req -config openssl_root.cnf -new -x509 -sha256 -extensions v3_ca \
      -key rca-$ORG_NAME/private/rca.$ORG_FULL_NAME.key.pem \
      -out rca-$ORG_NAME/certs/rca.$ORG_FULL_NAME.crt.pem -days 3650 \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=rca.$ORG_FULL_NAME"

    # Replace by default value
    sed -i "s/$CA_DIR/DIR_NAME/g" openssl_root.cnf
    sed -i "s/$ORG_FULL_NAME/ORG_NAME/g" openssl_root.cnf

  done
}

createIntermediateCAPrivateKeyAndCSR() {
  for i in ${!ORGANIZATION_NAME[@]}; do

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=${ORGANIZATION_NAME[$i]}.$DOMAIN
    ORG_DIR=$INTERMEDIATE_FABRIC_CA_DIR/crypto-config/peerOrganizations/${ORGANIZATION_NAME[$i]}.$DOMAIN
    CA_DIR=rca-${ORGANIZATION_NAME[$i]}

    #  # Replace Org directory & Org name
    sed -i "s/DIR_NAME/$CA_DIR/g" openssl_root.cnf
    sed -i "s/ORG_NAME/$ORG_FULL_NAME/g" openssl_root.cnf

    # Generate private key
    openssl ecparam -name prime256v1 -genkey -noout -out $ORG_DIR/ca/ica.$ORG_FULL_NAME.key.pem
    # INTERMEDIATE_CA self-sign his own Certificate Signing Request
    openssl req -new -sha256 \
      -key $ORG_DIR/ca/ica.$ORG_FULL_NAME.key.pem \
      -out $ORG_DIR/ca/ica.$ORG_FULL_NAME.csr \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=ica.$ORG_FULL_NAME"

    # ROOT_CA signs INTERMEDIATE_CA's Certificate Signing Request
    openssl ca -batch -config openssl_root.cnf -extensions v3_intermediate_ca -days 1825 -notext -md sha256 \
      -in $ORG_DIR/ca/ica.$ORG_FULL_NAME.csr \
      -out $ORG_DIR/ca/ica.$ORG_FULL_NAME.crt.pem

    # Replace by default value
    sed -i "s/$CA_DIR/DIR_NAME/g" openssl_root.cnf
    sed -i "s/$ORG_FULL_NAME/ORG_NAME/g" openssl_root.cnf

  done
}

CreateChainFile() {
  for i in ${!ORGANIZATION_NAME[@]}; do

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=${ORGANIZATION_NAME[$i]}.$DOMAIN
    ORG_DIR=$INTERMEDIATE_FABRIC_CA_DIR/crypto-config/peerOrganizations/${ORGANIZATION_NAME[$i]}.$DOMAIN

    cat $ORG_DIR/ca/ica.$ORG_FULL_NAME.crt.pem rca-$ORG_NAME/certs/rca.$ORG_FULL_NAME.crt.pem >$ORG_DIR/ca/chain.$ORG_FULL_NAME.crt.pem
  done
}

CreateFabricFolderStructure
createRootCAStructure
CreateRootCAPrivateKeyAndCSR
createIntermediateCAPrivateKeyAndCSR
CreateChainFile
