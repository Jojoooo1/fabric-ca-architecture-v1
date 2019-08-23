#!/bin/bash
set -e

# import var
export COMPOSE_PROJECT_NAME=net
export IMAGE_TAG=latest
export CA_TLS_ENABLED=true

DOMAIN=logistic
ORGANIZATION_DOMAIN="logistic"
ORGANIZATION_NAME=("shipper")
ORGANIZATION_TYPE=("peer")
ORGANIZATION_PEER_NUMBER=(2)

ORGANIZATION_CA_URL=("localhost:7054")
# Defined organization identity here individually
# CA admin is assigned by default to "admin"
# Admin@ORG_FULL_NAME is assigned by default to msp/admincerts
ORGANIZATION_USERS_shipper=("Admin@shipper.logistic")

# Folders
CONFIG_FOLDER=$PWD/crypto-config

if [ ! "$(ls -A $CONFIG_FOLDER)" ]; then
  echo "Build failed, Please build crypto-config folder first"
  exit 1
fi

docker-compose -f docker-compose-ca.yaml up -d ica.shipper.logistic

sleep 15 # need to wait tls backdated certificate

# Enroll boostrapped user
enrollBoostrappedAdmin() {
  for i in ${!ORGANIZATION_NAME[@]}; do

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=$ORG_NAME.$ORGANIZATION_DOMAIN
    ORG_DIR=$PWD/crypto-config/${ORGANIZATION_TYPE}Organizations/$ORG_FULL_NAME
    # boostrapped admin folder
    REGISTRAR_DIR=$ORG_DIR/users/admin
    # Sets identity as CA admin
    export FABRIC_CA_CLIENT_HOME=$REGISTRAR_DIR

    # Sets TLS certificate to communicate with fabric-ca
    export FABRIC_CA_CLIENT_TLS_CERTFILES=$ORG_DIR/tlsca/tls-chain.$ORG_FULL_NAME-cert.pem
    fabric-ca-client enroll --csr.names "O=$ORG_FULL_NAME,L=Sao Paulo,ST=Sao Paulo,C=BR" -m admin -u https://admin:adminpw@${ORGANIZATION_CA_URL[$i]} # -m, --myhost string  # Hostname to include in the certificate signing request during enrollment (default "$HOSTNAME")

    # CN: Common Name, O: Organization name, OU: Organizational Unit, L Location/city, ST: State, C: Country
    # [INFO] Created a default configuration file at $ORG_FULL_NAME/users/admin/fabric-ca-client-config.yaml
    # [INFO] generating key: & # {A:ecdsa S:256} # 2019/07/29 18:42:27 [INFO] encoded CSR
    # [INFO] Stored client certificate at users/admin/msp/signcerts/cert.pem
    # [INFO] Stored root CA certificate at users/admin/msp/cacerts/localhost-7054.pem
    # [INFO] Stored intermediate CA certificates at users/admin/msp/intermediatecerts/localhost-7054.pem
    # [INFO] Stored Issuer public key at users/admin/msp/IssuerPublicKey
    # [INFO] Stored Issuer revocation public key at users/admin/msp/IssuerRevocationPublicKey
  done

}

registerIdentity() {
  # Sets identity as CA admin for registering identity
  export FABRIC_CA_CLIENT_HOME=$REGISTRAR_DIR

  for i in ${!ORGANIZATION_NAME[@]}; do

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=$ORG_NAME.$DOMAIN
    ORG_DIR=$PWD/crypto-config/${ORGANIZATION_TYPE}Organizations/$ORG_FULL_NAME

    # Sets TLS certificate to communicate with fabric-ca
    export FABRIC_CA_CLIENT_TLS_CERTFILES=$ORG_DIR/tlsca/tls-chain.$ORG_FULL_NAME-cert.pem

    for ((j = 0; j < ${ORGANIZATION_PEER_NUMBER[$i]}; j++)); do
      IDENTITY_NAME="peer$j.$ORG_FULL_NAME"
      fabric-ca-client register --id.name $IDENTITY_NAME --id.secret mysecret --id.type peer -u https://${ORGANIZATION_CA_URL[$i]} # --id.attrs '"hf.Registrar.Roles=peer,client"' --id.attrs hf.Revoker=true
      # [INFO] Configuration file location: shipper.logistic/users/admin/fabric-ca-client-config.yaml
    done

    ORG_IDENTITY=ORGANIZATION_USERS_$ORG_NAME[@]
    for j in ${!ORG_IDENTITY}; do
      IDENTITY_NAME=$j
      fabric-ca-client register --id.name $IDENTITY_NAME --id.secret mysecret --id.type client -u https://${ORGANIZATION_CA_URL[$i]} # Identity performing the register command sets by **FABRIC_CA_CLIENT_HOME**
      # [INFO] Configuration file location: shipper.logistic/users/admin/fabric-ca-client-config.yaml
    done
  done
}

enrollIdentity() {
  for i in ${!ORGANIZATION_NAME[@]}; do

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=$ORG_NAME.$DOMAIN
    ORG_DIR=$PWD/crypto-config/${ORGANIZATION_TYPE}Organizations/$ORG_FULL_NAME

    # Sets TLS certificate to communicate with fabric-ca
    export FABRIC_CA_CLIENT_TLS_CERTFILES=$ORG_DIR/tlsca/tls-chain.$ORG_FULL_NAME-cert.pem

    # enroll PEERS
    for ((j = 0; j < ${ORGANIZATION_PEER_NUMBER[$i]}; j++)); do
      IDENTITY_NAME="peer$j.$ORG_FULL_NAME"
      IDENTITY_DIR=$ORG_DIR/peers/$IDENTITY_NAME

      export FABRIC_CA_CLIENT_HOME=$IDENTITY_DIR # loads identity $ORG_DIR/peers/peer0.$ORG_FULL_NAME
      fabric-ca-client enroll \
        --csr.names "C=BR,ST=Sao Paulo,L=Sao Paulo,O=$ORG_FULL_NAME" \
        -m $IDENTITY_NAME -u https://$IDENTITY_NAME:mysecret@${ORGANIZATION_CA_URL[$i]}
    done

    # enroll USERS
    ORG_IDENTITY=ORGANIZATION_USERS_$ORG_NAME[@]
    for j in ${!ORG_IDENTITY}; do
      IDENTITY_NAME=$j
      IDENTITY_DIR=$ORG_DIR/users/$IDENTITY_NAME

      export FABRIC_CA_CLIENT_HOME=$IDENTITY_DIR
      fabric-ca-client enroll \
        --csr.names "C=BR,ST=Sao Paulo,L=Sao Paulo,O=$ORG_FULL_NAME" \
        -m $IDENTITY_NAME -u https://$IDENTITY_NAME:mysecret@${ORGANIZATION_CA_URL[$i]}
    done

  done
}

copyAdminIdentityToAllMSPIdentity() {
  for i in ${!ORGANIZATION_NAME[@]}; do

    ORG_NAME=${ORGANIZATION_NAME[$i]}
    ORG_FULL_NAME=$ORG_NAME.$DOMAIN
    ORG_DIR=$PWD/crypto-config/${ORGANIZATION_TYPE}Organizations/$ORG_FULL_NAME

    # Copy admin signed cert in admincerts folder
    ADMIN_DIR=$ORG_DIR/users/Admin@$ORG_FULL_NAME
    cp $ADMIN_DIR/msp/signcerts/*.pem $ADMIN_DIR/msp/admincerts/Admin@$ORG_FULL_NAME-cert.pem

    # Copy in MSP ORG msp folder
    cp $ADMIN_DIR/msp/signcerts/*.pem $ORG_DIR/msp/admincerts/Admin@$ORG_FULL_NAME-cert.pem

    # copy Admin certificate to PEERS MSP
    for ((j = 0; j < ${ORGANIZATION_PEER_NUMBER[$i]}; j++)); do
      IDENTITY_NAME="peer$j.$ORG_FULL_NAME"
      IDENTITY_DIR=$ORG_DIR/peers/$IDENTITY_NAME
      cp $ADMIN_DIR/msp/signcerts/*.pem $IDENTITY_DIR/msp/admincerts/Admin@$ORG_FULL_NAME-cert.pem
    done

    # copy Admin certificate to USERS MSP
    ORG_IDENTITY=ORGANIZATION_USERS_$ORG_NAME[@]
    for j in ${!ORG_IDENTITY}; do
      IDENTITY_NAME=$j
      IDENTITY_DIR=$ORG_DIR/users/$IDENTITY_NAME
      cp $ADMIN_DIR/msp/signcerts/*.pem $IDENTITY_DIR/msp/admincerts/Admin@$ORG_FULL_NAME-cert.pem
    done

  done
}

enrollBoostrappedAdmin

sleep 20 # need to wait identity backdated certificate

registerIdentity
enrollIdentity
copyAdminIdentityToAllMSPIdentity
