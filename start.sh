#!/bin/bash

cd ./root-ca
./reset.sh && ./build.sh

sleep 2

cd ../network
./start-crypto.sh
