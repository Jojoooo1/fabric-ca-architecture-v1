#!/bin/bash
set -e

ORG_DIR=$PWD/crypto-config/peerOrganizations/org1.logistic

REGISTRAR_DIR=$ORG_DIR/users/ca-admin
ADMIN_DIR=$ORG_DIR/users/Admin@org1.logistic
PEER_DIR=$ORG_DIR/peers/peer0.org1.logistic

docker-compose -f docker-compose-ca.yaml up -d

sleep 15

# Fabric CA, by default, backdates the signing of certificates by 5 minutes

echo ########################################################
echo ##### CREATING ADMIN REGISTRAR & MSP TREE FOLDER #####
echo ########################################################
# Admin will be registered in REGISTRAR_DIR
export FABRIC_CA_CLIENT_HOME=$REGISTRAR_DIR
# Enroll the pre-registrar **ADMIN**. It Can register other users (cf. fabric-ca-server-config.yaml:registry.maxenrollments)
fabric-ca-client enroll --csr.names 'C=BR,ST=Sao Paulo,L=Sao Paulo,O=org1.logistic' -m ca-admin -u http://ca-admin:adminpw@localhost:7054 # -m, --myhost string  # Hostname to include in the certificate signing request during enrollment (default "$HOSTNAME")
# [INFO] Created a default configuration file at org1.logistic/users/admin/fabric-ca-client-config.yaml
# [INFO] generating key: & # {A:ecdsa S:256} # 2019/07/29 18:42:27 [INFO] encoded CSR
# [INFO] Stored client certificate at users/admin/msp/signcerts/cert.pem
# [INFO] Stored root CA certificate at users/admin/msp/cacerts/localhost-7054.pem
# [INFO] Stored intermediate CA certificates at users/admin/msp/intermediatecerts/localhost-7054.pem
# [INFO] Stored Issuer public key at users/admin/msp/IssuerPublicKey
# [INFO] Stored Issuer revocation public key at users/admin/msp/IssuerRevocationPublicKey

# Register User with Identity ca-admin loaded through ** FABRIC_CA_CLIENT_HOME=$REGISTRAR_DIR**
fabric-ca-client register --id.name Admin@org1.logistic --id.secret mysecret --id.type client --id.affiliation org1 -u http://localhost:7054
# [INFO] Configuration file location: org1.logistic/users/ca-admin/fabric-ca-client-config.yaml
fabric-ca-client register --id.name peer0.org1.logistic --id.secret mysecret --id.type peer --id.affiliation org1 -u http://localhost:7054
# [INFO] Configuration file location: org1.logistic/users/ca-admin/fabric-ca-client-config.yaml

echo                                    ########################################################
echo                                    ##### CREATING ADMIN CERTIFICATE & MSP TREE FOLDER #####
echo                                    ########################################################
# Enroll Admin@org1.logistic & define **Admin@org1.logistic** as **admin** by putting certificate in folder admincerts
export FABRIC_CA_CLIENT_HOME=$ADMIN_DIR # loads $ORG_DIR/users/Admin@org1.logistic
fabric-ca-client enroll \
  --csr.names 'C=BR,ST=Sao Paulo,L=Sao Paulo,O=org1.logistic' \
  -m Admin@org1.logistic -u http://Admin@org1.logistic:mysecret@localhost:7054
# 1. Define Admin@org1.logistic as admin
cp $ADMIN_DIR/msp/signcerts/*.pem $ADMIN_DIR/msp/admincerts/

echo                                   ########################################################
echo                                   ##### CREATING PEER CERTIFICATE & MSP TREE FOLDER ######
echo                                   ########################################################
# Enroll peer0.org1.logistic & define **Admin@org1.logistic** as **admin** by putting certificate in folder admincerts
export FABRIC_CA_CLIENT_HOME=$PEER_DIR # loads $ORG_DIR/peers/peer0.org1.logistic
fabric-ca-client enroll \
  --csr.names 'C=BR,ST=Sao Paulo,L=Sao Paulo,O=org1.logistic' \
  -m peer0.org1.logistic -u http://peer0.org1.logistic:mysecret@localhost:7054
# 2. Makes Admin@org1.logistic as Peer admin
cp $ADMIN_DIR/msp/signcerts/*.pem $PEER_DIR/msp/admincerts/

echo ########################################################
echo ######### CREATING ORG MSP FOLDER STRUCTURE ############
echo ########################################################
# 3. Makes Admin@org1.logistic an Org admin
cp $ADMIN_DIR/msp/signcerts/*.pem $ORG_DIR/msp/admincerts/
# Copy ca certs & intermediatecerts in Org MSP
cp $PEER_DIR/msp/cacerts/*.pem $ORG_DIR/msp/cacerts/
cp $PEER_DIR/msp/intermediatecerts/*.pem $ORG_DIR/msp/intermediatecerts/
