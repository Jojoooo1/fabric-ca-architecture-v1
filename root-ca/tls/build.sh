#!/bin/bash
set -e

# Organisations variables
CA_HOST=localhost
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

# shipper.logistic/users/Admin@shipper.logistic/tls/ca.crt
# shipper.logistic/users/Admin@shipper.logistic/tls/client.crt
# shipper.logistic/users/Admin@shipper.logistic/tls/key.crt
# shipper.logistic/users/Admin@shipper.logistic/msp/tlscacerts/tlsca.shipper.logistic-cert.pem

# shipper.logistic/users/peer0.shipper.logistic/tls/ca.crt
# shipper.logistic/users/peer0.shipper.logistic/tls/client.crt
# shipper.logistic/users/peer0.shipper.logistic/tls/key.crt
# shipper.logistic/peers/peer0.shipper.logistic/msp/tlscacerts/tlsca.shipper.logistic-cert.pem

########################
### Creating ROOT_CA ###
########################

createRootCAStructure() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    echo "Creating ROOT_CA artifacts for ${ORGANIZATION_NAME[$i]}"

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    # Creates roots directory
    mkdir -p tls-rca-$ORG_NAME/private tls-rca-$ORG_NAME/certs tls-rca-$ORG_NAME/newcerts tls-rca-$ORG_NAME/crl
    chmod 700 tls-rca-$ORG_NAME/private
    # Creates CA artifacts
    touch tls-rca-$ORG_NAME/index.txt tls-rca-$ORG_NAME/serial

    # Creates intermediate directory
    mkdir -p tls-ica-$ORG_NAME

    #touch tls-rca-$ORG_NAME/crl/index.txt tls-rca-$ORG_NAME/crl/serial

    # Creates serial number, mandatory for openssl ca config
    echo 1000 >tls-rca-$ORG_NAME/serial
    #echo 00 >tls-rca-$ORG_NAME/serial

  done
  echo "******************************"
  echo
}

CreateRootCAPrivateKeyAndCSR() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    echo "Creating ROOT_CA private key and CSR for ${ORGANIZATION_NAME[$i]}"

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=${ORGANIZATION_NAME[$i]}.$DOMAIN
    ORG_CA_DIR=tls-rca-${ORGANIZATION_NAME[$i]}

    # Replace Org directory & Org name
    sed -i "s/DIR_NAME/$ORG_CA_DIR/g" openssl_root.cnf
    sed -i "s/ORG_NAME/$ORG_FULL_NAME/g" openssl_root.cnf

    # Generate private key
    openssl ecparam -name prime256v1 -genkey -noout -out tls-rca-$ORG_NAME/private/tls-rca.$ORG_FULL_NAME.key.pem
    # ROOT_CA self-sign his own Certiftls-icate Signing Request
    openssl req -config openssl_root.cnf -new -x509 -sha256 -extensions v3_ca \
      -key tls-rca-$ORG_NAME/private/tls-rca.$ORG_FULL_NAME.key.pem \
      -out tls-rca-$ORG_NAME/certs/tls-rca.$ORG_FULL_NAME.crt.pem -days 3650 \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=$CA_HOST"

    # Reput the default value
    sed -i "s/$ORG_CA_DIR/DIR_NAME/g" openssl_root.cnf
    sed -i "s/$ORG_FULL_NAME/ORG_NAME/g" openssl_root.cnf

  done
  echo "******************************"
  echo
}

##########################
### Creating FABRIC_CA ###
##########################

CreateFabricFolderStructure() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    echo "Creating Fabric network crypto-config folder structure for ${ORGANIZATION_NAME[$i]}"

    # Orgs directory
    ORG_DIR=$FABRIC_CA_DIR/crypto-config/peerOrganizations/${ORGANIZATION_NAME[$i]}.$DOMAIN

    # Creates TLS for Peers & User & Orgs
    for j in 1 ${ORGANIZATION_PEER_NUMBER[$i]}; do
      PEER_DIR=$ORG_DIR/peers/peer$(($j - 1)).${ORGANIZATION_NAME[$i]}.$DOMAIN # Peer name start at 0
      mkdir -p $PEER_DIR/tls                                                   # Other directory will be created by fabric-ca-client
    done
    # Users
    # REGISTRAR_DIR=$ORG_DIR/users/tlsca-admin
    # mkdir -p $REGISTRAR_DIR
    mkdir -p $ORG_DIR/users/Admin@${ORGANIZATION_NAME[$i]}.$DOMAIN/msp/tlscacerts

    # TLSCA & MSP
    mkdir -p $ORG_DIR/tlsca
    mkdir -p $ORG_DIR/msp/tlscacerts # $ORG_DIR/msp/tlsintermediatecerts

  done

  echo "******************************"
  echo
}

createFabricCAPrivateKeyAndCSR() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    echo
    echo "Creating FABRIC_CA private key and CSR for ${ORGANIZATION_NAME[$i]}"
    echo

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=${ORGANIZATION_NAME[$i]}.$DOMAIN
    ORG_FABRIC_CA_DIR=$FABRIC_CA_DIR/crypto-config/peerOrganizations/${ORGANIZATION_NAME[$i]}.$DOMAIN
    ORG_CA_DIR=tls-rca-${ORGANIZATION_NAME[$i]}

    #  # Replace Org directory & Org name
    sed -i "s/DIR_NAME/$ORG_CA_DIR/g" openssl_root.cnf
    sed -i "s/ORG_NAME/$ORG_FULL_NAME/g" openssl_root.cnf

    # Creating FABRIC_CA_SERVER crypto-config

    # Generate private key
    openssl ecparam -name prime256v1 -genkey -noout \
      -out $ORG_FABRIC_CA_DIR/tlsca/tls-ica.$ORG_FULL_NAME.key.pem

    # INTERMEDIATE_CA self-sign his own Certiftls-icate Signing Request
    openssl req -new -sha256 \
      -key $ORG_FABRIC_CA_DIR/tlsca/tls-ica.$ORG_FULL_NAME.key.pem \
      -out $ORG_FABRIC_CA_DIR/tlsca/tls-ica.$ORG_FULL_NAME.csr \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=$CA_HOST"

    # ROOT_CA signs INTERMEDIATE_CA's Certiftls-icate Signing Request
    openssl ca -batch -config openssl_root.cnf -extensions v3_intermediate_ca -days 1825 -notext -md sha256 \
      -in $ORG_FABRIC_CA_DIR/tlsca/tls-ica.$ORG_FULL_NAME.csr \
      -out $ORG_FABRIC_CA_DIR/tlsca/tls-ica.$ORG_FULL_NAME.crt.pem

    # Replace by default value
    sed -i "s/$ORG_CA_DIR/DIR_NAME/g" openssl_root.cnf
    sed -i "s/$ORG_FULL_NAME/ORG_NAME/g" openssl_root.cnf
  done
  echo "******************************"
  echo
}

CreateChainFile() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    echo "Creating FABRIC_CA chainfile certiftls-icate for ${ORGANIZATION_NAME[$i]}"

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=${ORGANIZATION_NAME[$i]}.$DOMAIN
    ORG_FABRIC_CA_DIR=$FABRIC_CA_DIR/crypto-config/peerOrganizations/${ORGANIZATION_NAME[$i]}.$DOMAIN

    cat $ORG_FABRIC_CA_DIR/tlsca/tls-ica.$ORG_FULL_NAME.crt.pem tls-rca-$ORG_NAME/certs/tls-rca.$ORG_FULL_NAME.crt.pem >$ORG_DIR/tlsca/tls-chain.$ORG_FULL_NAME.crt.pem
  done
  echo "******************************"
  echo
}

createRootCAStructure
CreateRootCAPrivateKeyAndCSR
CreateFabricFolderStructure
createFabricCAPrivateKeyAndCSR
CreateChainFile
