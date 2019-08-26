# Enroll boostrapped CA user # default named admin
enrollBoostrappedAdmin() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Enrolling bootstrapped admin for $ORG_NAME..."

    ORG_FULL_NAME=$ORG_NAME.$ORGANIZATION_DOMAIN
    ORG_DIR=$PWD/crypto-config/peerOrganizations/$ORG_FULL_NAME
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
  echo "******************************"
}

registerIdentity() {
  echo "******************************"
  # Sets identity as CA admin for registering identity
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Registering organization identity for $ORG_NAME..."

    ORG_FULL_NAME=$ORG_NAME.$ORGANIZATION_DOMAIN
    ORG_DIR=$PWD/crypto-config/peerOrganizations/$ORG_FULL_NAME
    # boostrapped admin folder
    REGISTRAR_DIR=$ORG_DIR/users/admin

    # Sets identity as CA admin
    export FABRIC_CA_CLIENT_HOME=$REGISTRAR_DIR
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
  echo "******************************"
}

enrollIdentity() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Enrolling organization identity for $ORG_NAME..."

    ORG_FULL_NAME=$ORG_NAME.$ORGANIZATION_DOMAIN
    ORG_DIR=$PWD/crypto-config/peerOrganizations/$ORG_FULL_NAME

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
  echo "******************************"
}

copyAdminIdentityToMspFolder() {
  echo "******************************"
  for i in ${!ORGANIZATION_NAME[@]}; do
    ORG_NAME=${ORGANIZATION_NAME[$i]}
    echo "Copying admin certificate to MSP folder for $ORG_NAME..."

    ORG_FULL_NAME=$ORG_NAME.$ORGANIZATION_DOMAIN
    ORG_DIR=$PWD/crypto-config/peerOrganizations/$ORG_FULL_NAME

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
  echo "******************************"
}
