# Organisations variables
DOMAIN=logistic

ORGANIZATION_NAME=("shipper" "transporter" "insurance")
ORGANIZATION_TYPE=("peer" "peer" "peer")

ORGANIZATION_USERS_shipper=("admin" "Admin@shipper.$DOMAIN")
ORGANIZATION_USERS_transporter=("admin" "Admin@transporter.$DOMAIN")
ORGANIZATION_USERS_insurance=("admin" "Admin@insurance.$DOMAIN")

ORGANIZATION_PEER_NUMBER=(2 2 2)

CA_PREFIX="tls-"
TLS_CA=true

# Directories variables
ROOT_CA_DIR=$PWD
FABRIC_CA_DIR=$ROOT_CA_DIR/../../network # Fabric CA is created as intermediate CA
