#!/bin/bash
set -ev

ROOT_CA_DIR=$PWD
INTERMEDIATE_FABRIC_CA_DIR=$PWD/../intermediate-ca

# Remove ROOT_CA_CONFIG
rm -rf rca-*

# Remove INTERMEDIATE_CA_CONFIG
cd $INTERMEDIATE_FABRIC_CA_DIR
./reset.sh "CLEAN_ALL"
cd $ROOT_CA_DIR
