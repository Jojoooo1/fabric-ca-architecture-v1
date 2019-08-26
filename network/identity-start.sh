#!/bin/bash
set -e

# import var & utils lib
. ./scripts/env_var.sh
. ./scripts/utils-identity.sh

if [ ! "$(ls -A $CONFIG_FOLDER)" ]; then
  echo "Build failed, Please build crypto-config folder first"
  exit 1
fi

docker-compose -f docker-compose-ca.yaml up -d

sleep 25 # need to wait tls backdated certificate # Failed to verify certificate: x509: certificate has expired or is not yet valid

enrollBoostrappedAdmin

sleep 25 # need to wait identity backdated certificate # Failed to verify certificate: x509: certificate has expired or is not yet valid

registerIdentity
enrollIdentity
copyAdminIdentityToMspFolder
