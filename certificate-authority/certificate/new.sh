#!/bin/bash
set -e

# Organisations variables
DOMAIN=logistic
ORGANIZATION_NAME=shipper
NEW_ORGANIZATION_PREFIX=ica_2

if [ ! -d rca-shipper ]; then
  echo "Build failed, you need to create ROOT_CA first"
  exit 1
fi

########################
### Creating ICA ###
########################

createFabricCAPrivateKeyAndCSR() {
  echo "******************************"
  echo "Creating FABRIC_CA private key and CSR for $ORGANIZATION_NAME"
  echo

  ORG_NAME=$ORGANIZATION_NAME
  ORG_FULL_NAME=$ORGANIZATION_NAME.$DOMAIN
  # ORG_FABRIC_CA_DIR=$FABRIC_CA_DIR/crypto-config/peerOrganizations/$ORGANIZATION_NAME.$DOMAIN
  ORG_CA_DIR=rca-$ORGANIZATION_NAME

  #  # Replace Org directory & Org name
  sed -i "s/DIR_NAME/$ORG_CA_DIR/g" openssl_root.cnf
  sed -i "s/ORG_NAME/$ORG_FULL_NAME/g" openssl_root.cnf

  # Creating FABRIC_CA_SERVER crypto-config
  ICA_DIR=ica/$NEW_ORGANIZATION_PREFIX-$ORGANIZATION_NAME
  mkdir -p $ICA_DIR

  # Generate private key
  openssl ecparam -name prime256v1 -genkey -noout \
    -out $ICA_DIR/$NEW_ORGANIZATION_PREFIX.$ORG_FULL_NAME.key.pem

  # INTERMEDIATE_CA self-sign his own Certificate Signing Request
  openssl req -new -sha256 \
    -key $ICA_DIR/$NEW_ORGANIZATION_PREFIX.$ORG_FULL_NAME.key.pem \
    -out $ICA_DIR/$NEW_ORGANIZATION_PREFIX.$ORG_FULL_NAME.csr \
    -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=$NEW_ORGANIZATION_PREFIX.$ORG_FULL_NAME"

  # ROOT_CA signs INTERMEDIATE_CA's Certificate Signing Request
  openssl ca -batch -config openssl_root.cnf -extensions v3_intermediate_ca -days 1825 -notext -md sha256 \
    -in $ICA_DIR/$NEW_ORGANIZATION_PREFIX.$ORG_FULL_NAME.csr \
    -out $ICA_DIR/$NEW_ORGANIZATION_PREFIX.$ORG_FULL_NAME.crt.pem

  # Replace by default value
  sed -i "s/$ORG_CA_DIR/DIR_NAME/g" openssl_root.cnf
  sed -i "s/$ORG_FULL_NAME/ORG_NAME/g" openssl_root.cnf
  echo "******************************"
  echo
}

CreateChainFile() {
  echo "******************************"
  echo "Creating FABRIC_CA chainfile certificate for $ORGANIZATION_NAME"

  ORG_NAME=$ORGANIZATION_NAME
  ORG_FULL_NAME=$ORGANIZATION_NAME.$DOMAIN
  ICA_DIR=ica/$NEW_ORGANIZATION_PREFIX-$ORGANIZATION_NAME

  cat $ICA_DIR/$NEW_ORGANIZATION_PREFIX.$ORG_FULL_NAME.crt.pem rca-$ORG_NAME/certs/rca.$ORG_FULL_NAME.crt.pem >$ICA_DIR/chain.$ORG_FULL_NAME.crt.pem
  echo "******************************"
  echo
}

createFabricCAPrivateKeyAndCSR
CreateChainFile
