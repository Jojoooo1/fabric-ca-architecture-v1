#!/bin/bash
set -e

# import variable
. ./env.sh

if [ ! -d $FABRIC_CA_DIR ]; then
  echo "Build failed, Fabric network directory not found"
  exit 1
fi

./reset.sh
# Copy default config
cp -r ./config/* ./

########################
### Creating ROOT_CA ###
########################

createRootCAStructure() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Creating ROOT_CA artifacts for $ORG_NAME"

    ORG_RCA_DIR="root-ca/rca-$ORG_NAME"

    # Creates RCA directory
    mkdir -p $ORG_RCA_DIR/private $ORG_RCA_DIR/certs $ORG_RCA_DIR/newcerts $ORG_RCA_DIR/crl
    # chmod 700 $ORG_RCA_DIR/private
    # Creates RCA artifacts
    touch $ORG_RCA_DIR/index.txt $ORG_RCA_DIR/serial $ORG_RCA_DIR/crlnumber

    #touch $ORG_RCA_DIR/crl/index.txt $ORG_RCA_DIR/crl/serial

    # Creates serial/crlnumber number
    echo 1000 >$ORG_RCA_DIR/serial
    echo 1000 >$ORG_RCA_DIR/crlnumber

  done
  echo "******************************"
  echo
}

createRootCA() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Creating ROOT_CA private key and CSR for $ORG_NAME"

    ORG_FULL_NAME=$ORG_NAME.$DOMAIN
    ORG_RCA_DIR="root-ca/rca-$ORG_NAME"

    # Replace Org directory & Org name in config file
    sed -i -e "s#DIR_NAME#$ORG_RCA_DIR#" -e "#ORG_NAME#$ORG_FULL_NAME#" openssl_root.cnf

    # Creates RCA_TLS certificate
    # Generates private key
    openssl ecparam -name prime256v1 -genkey -noout \
      -out $ORG_RCA_DIR/private/${CA_PREFIX}rca.$ORG_FULL_NAME.key.pem
    # chmod 400 $ORG_RCA_DIR/private/${CA_PREFIX}rca.$ORG_FULL_NAME.key.pem
    # Creates CSR and self sign it (-config openssl_root.cnf/-extensions v3_ca/)
    openssl req -new -x509 -sha256 \
      -config openssl_root.cnf \
      -extensions v3_ca \
      -key $ORG_RCA_DIR/private/${CA_PREFIX}rca.$ORG_FULL_NAME.key.pem \
      -out $ORG_RCA_DIR/certs/${CA_PREFIX}rca.$ORG_FULL_NAME-cert.pem -days 3650 \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=${CA_PREFIX}rca.$ORG_FULL_NAME"

    # Reput default value in config file
    sed -i -e "s#$ORG_RCA_DIR#DIR_NAME#" -e "#$ORG_FULL_NAME#ORG_NAME#" openssl_root.cnf

  done
  echo "******************************"
  echo
}

########################
### Creating INTERMEDIATE_CA ###
########################

createIntermediateCA() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Creating INTERMEDIATE_CA private key and CSR for $ORG_NAME"

    ORG_FULL_NAME=$ORG_NAME.$DOMAIN

    ORG_RCA_DIR="root-ca/rca-$ORG_NAME"
    ORG_ICA_DIR="intermediate-ca/ica-$ORG_NAME"

    mkdir -p $ORG_ICA_DIR

    # # Creating folders
    # mkdir -p $ORG_ICA_DIR/ca # $ORG_ICA_DIR/msp/admincerts $ORG_ICA_DIR/msp/cacerts $ORG_ICA_DIR/msp/intermediatecerts # Peers intermediatecerts will be automatically created

    # # Creates Peer's org MSP directory
    # for ((j = 0; j < ${ORGANIZATION_PEER_NUMBER[$i]}; j++)); do # loop every peer
    #   PEER_NAME="peer$j.$ORG_FULL_NAME"
    #   PEER_DIR=$ORG_FABRIC_DIR/peers/$PEER_NAME # Peer name start at 0
    #   mkdir -p $PEER_DIR/msp/admincerts         # Other directory will be created by fabric-ca-client
    #   # $PEER_DIR/msp/intermediatecerts will be automatically created
    # done

    #  Replace Org directory & Org name in config file
    sed -i -e "s#DIR_NAME#$ORG_RCA_DIR#" -e "s#ORG_NAME#$ORG_FULL_NAME#" openssl_root.cnf
    sed -i -e "s#DIR_NAME#$ORG_ICA_DIR#" -e "s#ORG_NAME#$ORG_FULL_NAME#" openssl_intermediate.cnf

    # Creates ICA_TLS certificate
    # Generates private key
    openssl ecparam -name prime256v1 -genkey -noout \
      -out $ORG_ICA_DIR/${CA_PREFIX}ica.$ORG_FULL_NAME.key.pem

    # Creates CSR (-config openssl_intermediate.cnf)
    openssl req -new -sha256 \
      -config openssl_intermediate.cnf \
      -key $ORG_ICA_DIR/${CA_PREFIX}ica.$ORG_FULL_NAME.key.pem \
      -out $ORG_ICA_DIR/${CA_PREFIX}ica.$ORG_FULL_NAME.csr -days 3650 \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=${CA_PREFIX}ica.$ORG_FULL_NAME"

    # RCA signs CSR (-extensions v3_intermediate_ca/-config openssl_root.cnf)
    openssl ca -batch -days 1825 -notext -md sha256 \
      -config openssl_root.cnf \
      -extensions v3_intermediate_ca \
      -in $ORG_ICA_DIR/${CA_PREFIX}ica.$ORG_FULL_NAME.csr \
      -out $ORG_ICA_DIR/${CA_PREFIX}ica.$ORG_FULL_NAME-cert.pem

    # Reput default value in config file
    sed -i -e "s#$ORG_RCA_DIR#DIR_NAME#" -e "s#$ORG_FULL_NAME#ORG_NAME#" openssl_root.cnf
    sed -i -e "s#$ORG_ICA_DIR#DIR_NAME#" -e "s#$ORG_FULL_NAME#ORG_NAME#" openssl_intermediate.cnf

  done
  echo "******************************"
  echo
}

createFabricAdminCertFolder() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Creating Fabric network crypto-config folder structure for $ORG_NAME"

    # Creates admincerts for copying signed cert created

    # Orgs directory
    ORG_FULL_NAME=$ORG_NAME.$DOMAIN
    ORG_FABRIC_DIR=$FABRIC_CA_DIR/crypto-config/peerOrganizations/$ORG_FULL_NAME

    # Creates Peer's org MSP directory
    for j in 1 ${ORGANIZATION_PEER_NUMBER[$i]}; do
      PEER_DIR=$ORG_FABRIC_DIR/peers/peer$(($j - 1)).$ORG_FULL_NAME # Peer name start at 0
      mkdir -p $PEER_DIR/msp/admincerts                             # Other directory will be created by fabric-ca-client
      # $PEER_DIR/msp/intermediatecerts will be automatically created
    done

    # Users
    REGISTRAR_DIR=$ORG_FABRIC_DIR/users/admin # default identity used at fabric-ca-server instantiation # Will register the others identities
    ADMIN_DIR=$ORG_FABRIC_DIR/users/Admin@$ORG_FULL_NAME/msp/admincerts
    mkdir -p $REGISTRAR_DIR $ADMIN_DIR

    # CA & MSP
    mkdir -p $ORG_FABRIC_DIR/ca $ORG_FABRIC_DIR/msp/admincerts $ORG_FABRIC_DIR/msp/cacerts $ORG_FABRIC_DIR/msp/intermediatecerts # Peers intermediatecerts will be automatically created

    # Copy MSP OU identifier config
    cp ./config/config.yaml $ORG_FABRIC_DIR/msp/
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

    cat $ORG_ICA_DIR/${CA_PREFIX}ica.$ORG_FULL_NAME-cert.pem $ORG_RCA_DIR/certs/${CA_PREFIX}rca.$ORG_FULL_NAME-cert.pem >$ORG_ICA_DIR/${CA_PREFIX}chain.$ORG_FULL_NAME-cert.pem
  done
  echo "******************************"
  echo
}

##########################
### Creating FABRIC_CA ###
##########################

copyFilesToFabricCryptoConfig() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Copying FABRIC_CA Certificate to network folder for $ORG_NAME"

    ORG_FULL_NAME=$ORG_NAME.$DOMAIN
    ORG_RCA_DIR="root-ca/rca-$ORG_NAME"
    ORG_ICA_DIR="intermediate-ca/ica-$ORG_NAME"
    # Fabric DIR
    ORG_FABRIC_DIR=$FABRIC_CA_DIR/crypto-config/peerOrganizations/$ORG_NAME.$DOMAIN

    # Copy using default format in order to allow multiple orgs
    mkdir -p $ORG_FABRIC_DIR/ca
    cp $ORG_ICA_DIR/* $ORG_FABRIC_DIR/ca

    # Copy RCA/ICA to MSP folder
    cp $ORG_RCA_DIR/certs/${CA_PREFIX}rca.$ORG_FULL_NAME-cert.pem $ORG_FABRIC_DIR/msp/cacerts/
    cp $ORG_ICA_DIR/${CA_PREFIX}ica.$ORG_FULL_NAME-cert.pem $ORG_FABRIC_DIR/msp/intermediatecerts/
  done
  echo "******************************"
  echo
}

createRootCAStructure
createRootCA

createFabricAdminCertFolder

# createIntermediateCAStructure
createIntermediateCA
createIntermediateCAChain

copyFilesToFabricCryptoConfig

# remove default config
rm -rf ./openssl_*
