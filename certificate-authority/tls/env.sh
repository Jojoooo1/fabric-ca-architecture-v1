# Organisations variables
DOMAIN=logistic
ORGANIZATION_NAME=(shipper)
ORGANIZATION_PEER_NUMBER=(2)

ORGANIZATION_USERS_shipper=(admin Admin@$ORGANIZATION_NAME.$DOMAIN)

# Directories variables
ROOT_CA_DIR=$PWD
FABRIC_CA_DIR=$ROOT_CA_DIR/../../network # Fabric CA is created as intermediate CA
