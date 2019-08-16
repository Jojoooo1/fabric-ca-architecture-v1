#!/bin/bash
set -e

# Organisations variables
CA_HOST=localhost
DOMAIN=logistic
ORGANIZATION_NAME=(shipper)
ORGANIZATION_PEER_NUMBER=(2)
ORGANIZATION_USERS=(admin Admin@$ORGANIZATION_NAME.$DOMAIN)

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
    echo "Creating ROOT_CA artifacts for ${ORGANIZATION_NAME[$i]}"

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    # Creates roots & intermediate directory
    mkdir -p tls-rca-$ORG_NAME/private tls-rca-$ORG_NAME/certs tls-rca-$ORG_NAME/newcerts tls-rca-$ORG_NAME/crl
    chmod 700 tls-rca-$ORG_NAME/private
    # Creates CA artifacts
    touch tls-rca-$ORG_NAME/index.txt tls-rca-$ORG_NAME/serial

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
    ORG_RCA_DIR=tls-rca-${ORGANIZATION_NAME[$i]}

    # Replace Org directory & Org name
    sed -i "s/DIR_NAME/$ORG_RCA_DIR/g" openssl_root.cnf
    sed -i "s/ORG_NAME/$ORG_FULL_NAME/g" openssl_root.cnf

    # Generate private key
    openssl ecparam -name prime256v1 -genkey -noout \
      -out tls-rca-$ORG_NAME/private/tls-rca.$ORG_FULL_NAME.key.pem

    # ROOT_CA self-sign his own Certiftls-icate Signing Request
    openssl req -config openssl_root.cnf -new -x509 -sha256 -extensions v3_ca \
      -key tls-rca-$ORG_NAME/private/tls-rca.$ORG_FULL_NAME.key.pem \
      -out tls-rca-$ORG_NAME/certs/tls-rca.$ORG_FULL_NAME.crt.pem -days 3650 \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=$CA_HOST"

    # Reput the default value
    sed -i "s/$ORG_RCA_DIR/DIR_NAME/g" openssl_root.cnf
    sed -i "s/$ORG_FULL_NAME/ORG_NAME/g" openssl_root.cnf

  done
  echo "******************************"
  echo
}

createIntermediateCAStructure() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    echo "Creating ROOT_CA artifacts for ${ORGANIZATION_NAME[$i]}"

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_ICA_DIR=ica/tls-ica-${ORGANIZATION_NAME[$i]}

    # Creates roots & intermediate directory
    mkdir -p $ICA_DIR/private $ICA_DIR/certs $ICA_DIR/newcerts $ICA_DIR/crl
    chmod 700 $ICA_DIR/private
    # Creates CA artifacts
    touch $ICA_DIR/index.txt $ICA_DIR/serial

    #touch $ICA_DIR/crl/index.txt $ICA_DIR/crl/serial

    # Creates serial number, mandatory for openssl ca config
    echo 1000 >$ICA_DIR/serial
    #echo 00 >$ICA_DIR/serial

  done
  echo "******************************"
  echo
}

createIntermediateCAPrivateKeyAndCSR() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    echo
    echo "Creating FABRIC_CA private key and CSR for ${ORGANIZATION_NAME[$i]}"
    echo

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=${ORGANIZATION_NAME[$i]}.$DOMAIN

    ORG_RCA_DIR=rca-${ORGANIZATION_NAME[$i]}
    ORG_ICA_DIR=ica/tls-ica-${ORGANIZATION_NAME[$i]}

    #  # Replace Org directory & Org name
    sed -i "s/DIR_NAME/$ORG_RCA_DIR/g" openssl_root.cnf
    sed -i "s/ORG_NAME/$ORG_FULL_NAME/g" openssl_root.cnf

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

    # Replace by default value
    sed -i "s/$ORG_RCA_DIR/DIR_NAME/g" openssl_root.cnf
    sed -i "s/$ORG_FULL_NAME/ORG_NAME/g" openssl_root.cnf
  done
  echo "******************************"
  echo
}

generateIntermediateParticipantCertificate() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    echo
    echo "Creating FABRIC_CA private key and CSR for ${ORGANIZATION_NAME[$i]}"
    echo

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=${ORGANIZATION_NAME[$i]}.$DOMAIN
    ORG_ICA_DIR=ica/tls-ica-${ORGANIZATION_NAME[$i]}

    #  # Replace Org directory & Org name
    sed -i "s/DIR_NAME/$ORG_CA_DIR/g" openssl_intermediate.cnf
    sed -i "s/ORG_NAME/$ORG_FULL_NAME/g" openssl_intermediate.cnf

    # Creating FABRIC_CA_SERVER crypto-config
    ICA_DIR_PARTICIPANT=ica/tls-ica-${ORGANIZATION_NAME[$i]}/participants
    mkdir -p $ICA_DIR_PARTICIPANT

    # Creates Private Key
    for j in 1 ${ORGANIZATION_PEER_NUMBER[$i]}; do
      PEER_DIR=peer$(($j - 1)).${ORGANIZATION_NAME[$i]}.$DOMAIN # Peer name start at 0
      mkdir -p $PEER_DIR

      # Creates private key
      openssl ecparam -name prime256v1 -genkey -noout \
        -out $PEER_DIR/client.key

      # Self-sign Certificate
      openssl req -new -sha256 \
        -key $PEER_DIR/client.key \
        -out $PEER_DIR/client.csr \
        -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=$PEER_DIR"

      # INTERMEDIATE_CA sign Self-sign Certificate
      openssl ca -batch -config openssl_root.cnf -extensions v3_intermediate_ca -days 1825 -notext -md sha256 \
        -in $PEER_DIR/client.csr \
        -out $PEER_DIR/client.crt

    done

    for j in ${ORGANIZATION_USERS[$i]}; do
      USER_DIR=$j        # Peer name start at 0
      mkdir -p $USER_DIR # Other directory will be created by fabric-ca-client
      openssl ecparam -name prime256v1 -genkey -noout \
        -out $USER_DIR/client.key
    done

    # Generate private key

    # ROOT_CA signs INTERMEDIATE_CA's Certificate Signing Request
    openssl ca -batch -config openssl_root.cnf -extensions v3_intermediate_ca -days 1825 -notext -md sha256 \
      -in $ICA_DIR/tls-ica.$ORG_FULL_NAME.csr \
      -out $ICA_DIR/tls-ica.$ORG_FULL_NAME.crt.pem

    # Replace by default value
    sed -i "s/$ORG_CA_DIR/DIR_NAME/g" openssl_intermediate.cnf
    sed -i "s/$ORG_FULL_NAME/ORG_NAME/g" openssl_intermediate.cnf
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

    # Users TLSCA & TLS
    mkdir -p $ORG_DIR/users/admin/msp/tlscacerts -p $ORG_DIR/users/admin/tls
    mkdir -p $ORG_DIR/users/Admin@${ORGANIZATION_NAME[$i]}.$DOMAIN/msp/tlscacerts $ORG_DIR/users/Admin@${ORGANIZATION_NAME[$i]}.$DOMAIN/tls

    # ORG TLSCA & MSP
    mkdir -p $ORG_DIR/tlsca
    mkdir -p $ORG_DIR/msp/tlscacerts # $ORG_DIR/msp/tlsintermediatecerts

  done

  echo "******************************"
  echo
}

CopyFilesToFabricCryptoConfig() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    echo "Copying FABRIC_CA Certificate to network folder for ${ORGANIZATION_NAME[$i]}"

    ORG_FULL_NAME=${ORGANIZATION_NAME[$i]}.$DOMAIN

    ICA_DIR=ica/tls-ica-${ORGANIZATION_NAME[$i]}
    ORG_DIR=$FABRIC_CA_DIR/crypto-config/peerOrganizations/${ORGANIZATION_NAME[$i]}.$DOMAIN

    cp $ICA_DIR/tls-ica.$ORG_FULL_NAME.crt.pem $ORG_DIR/users/admin/msp/tlscacerts/tlsca.$ORG_FULL_NAME-cert.pem
    cp $ICA_DIR/tls-ica.$ORG_FULL_NAME.crt.pem $ORG_DIR/users/admin/msp/tlscacerts/tls/ca.crt

    cp $ICA_DIR/tls-ica.$ORG_FULL_NAME.crt.pem $ORG_DIR/users/Admin@$ORG_FULL_NAME/msp/tlscacerts/tlsca.$ORG_FULL_NAME-cert.pem
    cp $ICA_DIR/tls-ica.$ORG_FULL_NAME.crt.pem $ORG_DIR/users/Admin@$ORG_FULL_NAME/tls/ca.crt

    cp $ICA_DIR/tls-ica.$ORG_FULL_NAME.crt.pem $ORG_DIR/peers/peer0.$ORG_FULL_NAME/msp/tlscacerts/tlsca.$ORG_FULL_NAME-cert.pem
    cp $ICA_DIR/tls-ica.$ORG_FULL_NAME.crt.pem $ORG_DIR/peers/peer0.$ORG_FULL_NAME/tls/ca.crt

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

createFabricFolderStructure
createFabricCAPrivateKeyAndCSR
createChainFile
