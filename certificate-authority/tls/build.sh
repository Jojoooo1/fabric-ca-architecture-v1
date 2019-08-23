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

    # Creates ICA directory
    mkdir -p $ORG_ICA_DIR/private $ORG_ICA_DIR/certs $ORG_ICA_DIR/newcerts $ORG_ICA_DIR/crl
    # chmod 700 $ORG_ICA_DIR/private
    # Creates ICA artifacts
    touch $ORG_ICA_DIR/index.txt $ORG_ICA_DIR/serial $ORG_ICA_DIR/crlnumber

    #touch $ORG_ICA_DIR/crl/index.txt $ORG_ICA_DIR/crl/serial

    # Creates serial number, mandatory for openssl ca config
    echo 1000 >$ORG_ICA_DIR/serial
    echo 1000 >$ORG_ICA_DIR/crlnumber
    #echo 00 >$ORG_ICA_DIR/serial

  done
  echo "******************************"
  echo
}

createIntermediateCA() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo
    echo "Creating INTERMEDIATE_CA private key and CSR for $ORG_NAME"
    echo

    ORG_FULL_NAME=$ORG_NAME.$DOMAIN

    ORG_RCA_DIR="root-ca/rca-$ORG_NAME"
    ORG_ICA_DIR="intermediate-ca/ica-$ORG_NAME"

    #  Replace Org directory & Org name in config file
    sed -i -e "s#DIR_NAME#$ORG_RCA_DIR#" -e "s#ORG_NAME#$ORG_FULL_NAME#" openssl_root.cnf
    sed -i -e "s#DIR_NAME#$ORG_ICA_DIR#" -e "s#ORG_NAME#$ORG_FULL_NAME#" openssl_intermediate.cnf

    # Creates ICA_TLS certificate
    # Generates private key
    openssl ecparam -name prime256v1 -genkey -noout \
      -out $ORG_ICA_DIR/private/${CA_PREFIX}ica.$ORG_FULL_NAME.key.pem
    # chmod 400 $ORG_ICA_DIR/private/${CA_PREFIX}ica.$ORG_FULL_NAME.key.pem

    # Creates CSR (-config openssl_intermediate.cnf)
    openssl req -new -sha256 \
      -config openssl_intermediate.cnf \
      -key $ORG_ICA_DIR/private/${CA_PREFIX}ica.$ORG_FULL_NAME.key.pem \
      -out $ORG_ICA_DIR/certs/${CA_PREFIX}ica.$ORG_FULL_NAME.csr -days 3650 \
      -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=${CA_PREFIX}ica.$ORG_FULL_NAME"

    # RCA signs CSR (-extensions v3_intermediate_ca/-config openssl_root.cnf)
    openssl ca -batch -days 1825 -notext -md sha256 \
      -config openssl_root.cnf \
      -extensions v3_intermediate_ca \
      -in $ORG_ICA_DIR/certs/${CA_PREFIX}ica.$ORG_FULL_NAME.csr \
      -out $ORG_ICA_DIR/certs/${CA_PREFIX}ica.$ORG_FULL_NAME-cert.pem

    # Reput default value in config file
    sed -i -e "s#$ORG_RCA_DIR#DIR_NAME#" -e "s#$ORG_FULL_NAME#ORG_NAME#" openssl_root.cnf
    sed -i -e "s#$ORG_ICA_DIR#DIR_NAME#" -e "s#$ORG_FULL_NAME#ORG_NAME#" openssl_intermediate.cnf

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

    cat $ORG_ICA_DIR/certs/${CA_PREFIX}ica.$ORG_FULL_NAME-cert.pem $ORG_RCA_DIR/certs/${CA_PREFIX}rca.$ORG_FULL_NAME-cert.pem >$ORG_ICA_DIR/${CA_PREFIX}chain.$ORG_FULL_NAME-cert.pem
  done
  echo "******************************"
  echo
}

##########################
### Creating FABRIC_CERT ###
##########################

generateIntermediateCAIdentityTLS() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo
    echo "Creating FABRIC_IDENTITY private key and CSR for $ORG_NAME"
    echo

    ORG_FULL_NAME=$ORG_NAME.$DOMAIN

    ORG_RCA_DIR="root-ca/rca-$ORG_NAME"
    ORG_ICA_DIR="intermediate-ca/ica-$ORG_NAME"
    ORG_ICA_IDENTITY_DIR="intermediate-ca/ica-$ORG_NAME-identity/$ORG_FULL_NAME"

    #  Replace Org directory & Org name
    sed -i -e "s#DIR_NAME#$ORG_ICA_DIR#" -e "s#ORG_NAME#$ORG_FULL_NAME#" openssl_intermediate.cnf

    # **PEERS** Creates TLS certificates (server)
    for ((j = 0; j < ${ORGANIZATION_PEER_NUMBER[$i]}; j++)); do # loop every peer
      IDENTITY_NAME="peer$j.$ORG_FULL_NAME"
      ORG_ICA_IDENTITY_IDENTITY_MSP_DIR="$ORG_ICA_IDENTITY_DIR/peers/$IDENTITY_NAME/msp"
      ORG_ICA_IDENTITY_IDENTITY_TLS_DIR="$ORG_ICA_IDENTITY_DIR/peers/$IDENTITY_NAME/tls"

      # Creates folders
      mkdir -p "$ORG_ICA_IDENTITY_IDENTITY_MSP_DIR/tlscacerts" \
        -p "$ORG_ICA_IDENTITY_IDENTITY_MSP_DIR/tlsintermediatecerts" \
        -p "$ORG_ICA_IDENTITY_IDENTITY_TLS_DIR"

      # Creates private key
      openssl ecparam -name prime256v1 -genkey -noout \
        -out $ORG_ICA_IDENTITY_IDENTITY_TLS_DIR/server.key
      # # chmod 400 chmod

      # Creates CSR (-config openssl_intermediate.cnf \)
      openssl req -new -sha256 \
        -config openssl_intermediate.cnf \
        -key $ORG_ICA_IDENTITY_IDENTITY_TLS_DIR/server.key \
        -out $ORG_ICA_IDENTITY_IDENTITY_TLS_DIR/server.csr \
        -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=$IDENTITY_NAME"

      # ICA sign CSR
      openssl ca -batch \
        -config openssl_intermediate.cnf \
        -extensions server_cert -days 365 -notext -md sha256 \
        -in $ORG_ICA_IDENTITY_IDENTITY_TLS_DIR/server.csr \
        -out $ORG_ICA_IDENTITY_IDENTITY_TLS_DIR/server.crt

      # **!!** RENAME CHAIN CERT TO ca.cert to KEEP SAME FABRIC FORMAT FOR ALL PEER **!!**
      cp $ORG_ICA_DIR/${CA_PREFIX}chain.$ORG_FULL_NAME-cert.pem $ORG_ICA_IDENTITY_IDENTITY_TLS_DIR/ca.crt
      # Copy RCA/ICA/CHAIN cert in PEER_FOLDER
      cp $ORG_RCA_DIR/certs/${CA_PREFIX}rca.$ORG_FULL_NAME-cert.pem $ORG_ICA_IDENTITY_IDENTITY_MSP_DIR/tlscacerts
      cp $ORG_ICA_DIR/certs/${CA_PREFIX}ica.$ORG_FULL_NAME-cert.pem $ORG_ICA_IDENTITY_IDENTITY_MSP_DIR/tlsintermediatecerts
    done

    # **USERS** Creates TLS certificates (client)
    ORG_IDENTITY=ORGANIZATION_USERS_$ORG_NAME[@]
    for j in ${!ORG_IDENTITY}; do
      IDENTITY_NAME=$j
      ORG_ICA_IDENTITY_IDENTITY_MSP_DIR="$ORG_ICA_IDENTITY_DIR/users/$IDENTITY_NAME/msp"
      ORG_ICA_IDENTITY_IDENTITY_TLS_DIR="$ORG_ICA_IDENTITY_DIR/users/$IDENTITY_NAME/tls"

      # Creates folders
      mkdir -p "$ORG_ICA_IDENTITY_IDENTITY_MSP_DIR/tlscacerts" \
        -p "$ORG_ICA_IDENTITY_IDENTITY_MSP_DIR/tlsintermediatecerts" \
        -p "$ORG_ICA_IDENTITY_IDENTITY_TLS_DIR"

      # Creates private key
      openssl ecparam -name prime256v1 -genkey -noout \
        -out $ORG_ICA_IDENTITY_IDENTITY_TLS_DIR/client.key
      # # chmod 400 chmod

      # Creates CSR (-config openssl_intermediate.cnf \)
      openssl req -new -sha256 \
        -config openssl_intermediate.cnf \
        -key $ORG_ICA_IDENTITY_IDENTITY_TLS_DIR/client.key \
        -out $ORG_ICA_IDENTITY_IDENTITY_TLS_DIR/client.csr \
        -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=$IDENTITY_NAME.$ORG_FULL_NAME"

      # ICA sign CSR
      openssl ca -batch \
        -config openssl_intermediate.cnf \
        -extensions usr_cert -days 365 -notext -md sha256 \
        -in $ORG_ICA_IDENTITY_IDENTITY_TLS_DIR/client.csr \
        -out $ORG_ICA_IDENTITY_IDENTITY_TLS_DIR/client.crt

      # **!!** RENAME CHAIN CERT TO ca.cert to KEEP SAME FABRIC FORMAT FOR ALL PEER **!!**
      cp $ORG_ICA_DIR/${CA_PREFIX}chain.$ORG_FULL_NAME-cert.pem $ORG_ICA_IDENTITY_IDENTITY_TLS_DIR/ca.crt
      # Copy RCA/ICA/CHAIN cert in PEER_FOLDER
      cp $ORG_RCA_DIR/certs/${CA_PREFIX}rca.$ORG_FULL_NAME-cert.pem $ORG_ICA_IDENTITY_IDENTITY_MSP_DIR/tlscacerts
      cp $ORG_ICA_DIR/certs/${CA_PREFIX}ica.$ORG_FULL_NAME-cert.pem $ORG_ICA_IDENTITY_IDENTITY_MSP_DIR/tlsintermediatecerts
    done

    # Creates TLS certificates for TLSCA aka FABRIC_CA (server)
    if [ ! -d $TLS_CA ]; then
      IDENTITY_NAME="tlsca"
      ORG_ICA_IDENTITY_CA_DIR=$ORG_ICA_IDENTITY_DIR/$IDENTITY_NAME
      mkdir -p $ORG_ICA_IDENTITY_CA_DIR

      # Creates private key
      openssl ecparam -name prime256v1 -genkey -noout \
        -out $ORG_ICA_IDENTITY_CA_DIR/server.key
      # # chmod 400 chmod

      # Creates CSR
      openssl req -new -sha256 \
        -config openssl_intermediate.cnf \
        -key $ORG_ICA_IDENTITY_CA_DIR/server.key \
        -out $ORG_ICA_IDENTITY_CA_DIR/server.csr \
        -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=$ORG_FULL_NAME/OU=/CN=$IDENTITY_NAME.shipper.logistic" # x509: certificate is not valid for any names, but wanted to match localhost
      # /CN=$IDENTITY_NAME.$ORG_FULL_NAME

      # ICA sign CSR
      openssl ca -batch \
        -config openssl_intermediate.cnf \
        -extensions server_cert -days 365 -notext -md sha256 \
        -extensions req_ext -days 365 -notext -md sha256 \
        -in $ORG_ICA_IDENTITY_CA_DIR/server.csr \
        -out $ORG_ICA_IDENTITY_CA_DIR/server.crt

      # **!!** RENAME CHAIN CERT TO ca.cert to KEEP SAME FABRIC FORMAT FOR ALL PEER **!!**
      cp $ORG_ICA_DIR/${CA_PREFIX}chain.$ORG_FULL_NAME-cert.pem $ORG_ICA_IDENTITY_CA_DIR
      # Copy RCA/ICA/CHAIN cert in PEER_FOLDER
      cp $ORG_RCA_DIR/certs/${CA_PREFIX}rca.$ORG_FULL_NAME-cert.pem $ORG_ICA_IDENTITY_CA_DIR
      cp $ORG_ICA_DIR/certs/${CA_PREFIX}ica.$ORG_FULL_NAME-cert.pem $ORG_ICA_IDENTITY_CA_DIR
    fi

    # Copy RCA/ICA cert in ORG MSP FOLDER
    ORG_ICA_IDENTITY_ORG_MSP_DIR="$ORG_ICA_IDENTITY_DIR/msp"
    mkdir -p $ORG_ICA_IDENTITY_ORG_MSP_DIR/tlscacerts -p $ORG_ICA_IDENTITY_ORG_MSP_DIR/tlsintermediatecerts
    cp $ORG_RCA_DIR/certs/${CA_PREFIX}rca.$ORG_FULL_NAME-cert.pem $ORG_ICA_IDENTITY_ORG_MSP_DIR/tlscacerts
    cp $ORG_ICA_DIR/certs/${CA_PREFIX}ica.$ORG_FULL_NAME-cert.pem $ORG_ICA_IDENTITY_ORG_MSP_DIR/tlsintermediatecerts

    # Reput default value in config file
    sed -i -e "s#$ORG_ICA_DIR#DIR_NAME#" -e "s#$ORG_FULL_NAME#ORG_NAME#" openssl_intermediate.cnf

  done
  echo "******************************"
  echo
}

copyFilesToFabricFolder() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_TYPE=${ORGANIZATION_TYPE[$i]}

    echo "Copying FABRIC_CA Certificate to network folder for $ORG_NAME"

    ORG_FULL_NAME=$ORG_NAME.$DOMAIN
    ORG_RCA_DIR="root-ca/rca-$ORG_NAME"
    ORG_ICA_IDENTITY_DIR="intermediate-ca/ica-$ORG_NAME-identity/$ORG_FULL_NAME"

    cp -n -r $ORG_ICA_IDENTITY_DIR "$FABRIC_CA_DIR/crypto-config/${ORG_TYPE}Organizations/"

  done
  echo "******************************"
  echo
}

createRootCAStructure
createRootCA

createIntermediateCAStructure
createIntermediateCA
createIntermediateCAChain

generateIntermediateCAIdentityTLS

copyFilesToFabricFolder

# remove default config
rm -rf ./openssl_*
