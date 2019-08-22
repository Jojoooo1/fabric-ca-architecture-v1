#!/bin/bash
set -e

dir=$PWD

$dir/reset.sh

cd $dir/certificate-authority/certificate && ./build.sh
cd $dir/certificate-authority/tls && ./build.sh

sleep 4

cd ../../network
./start-crypto.sh
./build.sh
./start.sh

cd $dir
