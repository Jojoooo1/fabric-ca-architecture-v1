#!/bin/bash

dir=$PWD

cd ./root-ca
./reset.sh && ./build.sh

sleep 4

cd ../network
./start-crypto.sh

./build.sh

./start.sh

cd $dir
