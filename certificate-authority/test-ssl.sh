#!/bin/bash

# Verify TLS client with ICA chain
openssl verify -CAfile tls/intermediate-ca/ica-shipper/tls-chain.shipper.logistic.crt.pem tls/intermediate-ca/ica-shipper-identity/tlsca/server.crt
