#!/bin/bash
set -e

# Organisations variables
DOMAIN=logistic
ORGANIZATION_NAME=(shipper)
ORGANIZATION_PEER_NUMBER=(2)

# Directories variables
ROOT_CA_DIR=$PWD
FABRIC_CA_DIR=$PWD/../network # Fabric CA is created as intermediate CA

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
    echo "Creating ROOT_CA artifacts for ${ORGANIZATION_NAME[$i]}"

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
  echo "******************************"
  echo
}

CreateRootCAPrivateKeyAndCSR() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    echo "Creating ROOT_CA private key and CSR for ${ORGANIZATION_NAME[$i]}"

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=${ORGANIZATION_NAME[$i]}.$DOMAIN
    ORG_CA_DIR=rca-${ORGANIZATION_NAME[$i]}

    # Replace Org directory & Org name
    sed -i "s/DIR_NAME/$ORG_CA_DIR/g" openssl_root.cnf
    sed -i "s/ORG_NAME/$ORG_FULL_NAME/g" openssl_root.cnf

    # Generate private key
    openssl ecparam -name prime256v1 -genkey -noout -out rca-$ORG_NAME/private/rca.$ORG_FULL_NAME.key.pem
    # ROOT_CA self-sign his own Certificate Signing Request
    openssl req -config openssl_root.cnf -new -x509 -sha256 -extensions v3_ca \
      -key rca-$ORG_NAME/private/rca.$ORG_FULL_NAME.key.pem \
      -out rca-$ORG_NAME/certs/rca.$ORG_FULL_NAME.crt.pem -days 3650 \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=rca.$ORG_FULL_NAME"

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

    # Creates Peer's org MSP directory
    for j in 1 ${ORGANIZATION_PEER_NUMBER[$i]}; do
      PEER_DIR=$ORG_DIR/peers/peer$(($j - 1)).${ORGANIZATION_NAME[$i]}.$DOMAIN # Peer name start at 0

      mkdir -p $PEER_DIR/msp/admincerts # Other directory will be created by fabric-ca-client
    done

    # Creates Users's org MSP directory
    REGISTRAR_DIR=$ORG_DIR/users/admin # default identity used at fabric-ca-server instantiation # Will register the others identities
    ADMIN_DIR=$ORG_DIR/users/Admin@${ORGANIZATION_NAME[$i]}.$DOMAIN/msp/admincerts

    mkdir -p $REGISTRAR_DIR $ADMIN_DIR

    # Creates CA and Orgs MSP directories
    mkdir -p $ORG_DIR/ca $ORG_DIR/msp/admincerts $ORG_DIR/msp/intermediatecerts $ORG_DIR/msp/cacerts

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
    ORG_CA_DIR=rca-${ORGANIZATION_NAME[$i]}

    #  # Replace Org directory & Org name
    sed -i "s/DIR_NAME/$ORG_CA_DIR/g" openssl_root.cnf
    sed -i "s/ORG_NAME/$ORG_FULL_NAME/g" openssl_root.cnf

    # Creating FABRIC_CA_SERVER crypto-config

    # Generate private key
    openssl ecparam -name prime256v1 -genkey -noout \
      -out $ORG_FABRIC_CA_DIR/ca/ica.$ORG_FULL_NAME.key.pem

    # INTERMEDIATE_CA self-sign his own Certificate Signing Request
    openssl req -new -sha256 \
      -key $ORG_FABRIC_CA_DIR/ca/ica.$ORG_FULL_NAME.key.pem \
      -out $ORG_FABRIC_CA_DIR/ca/ica.$ORG_FULL_NAME.csr \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=ica.$ORG_FULL_NAME"

    # ROOT_CA signs INTERMEDIATE_CA's Certificate Signing Request
    openssl ca -batch -config openssl_root.cnf -extensions v3_intermediate_ca -days 1825 -notext -md sha256 \
      -in $ORG_FABRIC_CA_DIR/ca/ica.$ORG_FULL_NAME.csr \
      -out $ORG_FABRIC_CA_DIR/ca/ica.$ORG_FULL_NAME.crt.pem

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
    echo "Creating FABRIC_CA chainfile certificate for ${ORGANIZATION_NAME[$i]}"

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=${ORGANIZATION_NAME[$i]}.$DOMAIN
    ORG_FABRIC_CA_DIR=$FABRIC_CA_DIR/crypto-config/peerOrganizations/${ORGANIZATION_NAME[$i]}.$DOMAIN

    cat $ORG_FABRIC_CA_DIR/ca/ica.$ORG_FULL_NAME.crt.pem rca-$ORG_NAME/certs/rca.$ORG_FULL_NAME.crt.pem >$ORG_DIR/ca/chain.$ORG_FULL_NAME.crt.pem
  done
  echo "******************************"
  echo
}

createRootCAStructure
CreateRootCAPrivateKeyAndCSR
CreateFabricFolderStructure
createFabricCAPrivateKeyAndCSR
CreateChainFile
