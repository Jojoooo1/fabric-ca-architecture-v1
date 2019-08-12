#!/bin/bash
set -e

ORG_DOMAIN=logistic
ORG_NAME=shipper

ORG_DIR=$PWD/crypto-config/peerOrganizations/$ORG_NAME.$ORG_DOMAIN

REGISTRAR_DIR=$ORG_DIR/users/admin # default identity used at fabric-ca-server instantiation # Will register the others identities
ADMIN_DIR=$ORG_DIR/users/Admin@$ORG_NAME.$ORG_DOMAIN
PEER_DIR=$ORG_DIR/peers/peer0.$ORG_NAME.$ORG_DOMAIN

if [ ! -d $ORG_DIR ] || [ ! -d $REGISTRAR_DIR ] || [ ! -d $ADMIN_DIR ] || [ ! -d $PEER_DIR ]; then
  echo "Build failed, Please build ROOT_CA artifacts first"
  exit 1
fi

docker-compose -f docker-compose-ca.yaml up -d

sleep 4

# Fabric CA, by default, backdates the signing of certificates by 5 minutes
echo
echo "####################################"
echo "##### Enrolling identity admin #####"
echo "####################################"
# Admin will be registered in REGISTRAR_DIR
export FABRIC_CA_CLIENT_HOME=$REGISTRAR_DIR
# Enroll the pre-registered admin (defined at fabric-ca-server instantiation) & uses CSR section defined in client configuration file (csr.cn field must be set to the ID of the bootstrap identity)
fabric-ca-client enroll --csr.names "O=$ORG_NAME.$ORG_DOMAIN,L=Sao Paulo,ST=Sao Paulo,C=BR" -m admin -u http://admin:adminpw@localhost:7054 # -m, --myhost string  # Hostname to include in the certificate signing request during enrollment (default "$HOSTNAME")
# CN: Common Name, O: Organization name, OU: Organizational Unit, L Location/city, ST: State, C: Country
# [INFO] Created a default configuration file at org1.logistic/users/admin/fabric-ca-client-config.yaml
# [INFO] generating key: & # {A:ecdsa S:256} # 2019/07/29 18:42:27 [INFO] encoded CSR
# [INFO] Stored client certificate at users/admin/msp/signcerts/cert.pem
# [INFO] Stored root CA certificate at users/admin/msp/cacerts/localhost-7054.pem
# [INFO] Stored intermediate CA certificates at users/admin/msp/intermediatecerts/localhost-7054.pem
# [INFO] Stored Issuer public key at users/admin/msp/IssuerPublicKey
# [INFO] Stored Issuer revocation public key at users/admin/msp/IssuerRevocationPublicKey

sleep 2

echo
echo "##########################################################################"
echo "##### Registering identity Admin@org1.logistic & peer0.org1.logistic #####"
echo "##########################################################################"
# Identity performing the register command sets by **FABRIC_CA_CLIENT_HOME**
# can also use command: fabric-ca-client identity add Admin@org1.logistic --json '{"secret": "mysecret", "type": "client", "affiliation": "org1", "max_enrollments": 0}'
fabric-ca-client register --id.name Admin@$ORG_NAME.$ORG_DOMAIN --id.secret mysecret --id.type client -u http://localhost:7054 # --id.attrs 'hf.Revoker=true,admin=true:ecert'
# [INFO] Configuration file location: org1.logistic/users/admin/fabric-ca-client-config.yaml
fabric-ca-client register --id.name peer0.$ORG_NAME.$ORG_DOMAIN --id.secret mysecret --id.type peer -u http://localhost:7054 # --id.attrs '"hf.Registrar.Roles=peer,client"' --id.attrs hf.Revoker=true
# [INFO] Configuration file location: org1.logistic/users/admin/fabric-ca-client-config.yaml

echo
echo "##################################################"
echo "##### Enrolling identity Admin@org1.logistic #####"
echo "##################################################"
export FABRIC_CA_CLIENT_HOME=$ADMIN_DIR # loads identity $ORG_DIR/users/Admin@org1.logistic
fabric-ca-client enroll \
  --csr.names "C=BR,ST=Sao Paulo,L=Sao Paulo,O=org1.$ORG_DOMAIN" \
  -m Admin@$ORG_NAME.$ORG_DOMAIN -u http://Admin@org1.logistic:mysecret@localhost:7054

echo
echo "##################################################"
echo "##### Enrolling identity peer0.org1.logistic #####"
echo "##################################################"
export FABRIC_CA_CLIENT_HOME=$PEER_DIR # loads identity $ORG_DIR/peers/peer0.org1.logistic
fabric-ca-client enroll \
  --csr.names "C=BR,ST=Sao Paulo,L=Sao Paulo,O=org1.$ORG_DOMAIN" \
  -m peer0.$ORG_NAME.$ORG_DOMAIN -u http://peer0.org1.logistic:mysecret@localhost:7054

# Copying Admin@org1.logistic cert in admincerts folder to follow MSP structure
cp $ADMIN_DIR/msp/signcerts/*.pem $ADMIN_DIR/msp/admincerts/

echo
echo "##################################################################"
echo "##### Defining Admin@org1.logistic as admin of Peer and Orgs #####"
echo "##################################################################"
cp $ADMIN_DIR/msp/signcerts/*.pem $PEER_DIR/msp/admincerts/
cp $ADMIN_DIR/msp/signcerts/*.pem $ORG_DIR/msp/admincerts/
# Copy ca certs & intermediatecerts (taken from dir created by ca) in Org MSP
cp $PEER_DIR/msp/cacerts/*.pem $ORG_DIR/msp/cacerts/
cp $PEER_DIR/msp/intermediatecerts/*.pem $ORG_DIR/msp/intermediatecerts/
