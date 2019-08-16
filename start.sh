#!/bin/bash
set -e

dir=$PWD

$dir/reset.sh

cd $dir/root-ca/certificate && ./build.sh
cd $dir/root-ca/tls && ./build.sh

sleep 4

cd ../../network
./start-crypto.sh

cd $dir
