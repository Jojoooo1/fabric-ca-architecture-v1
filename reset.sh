#!/bin/bash
set -e

dir=$PWD

cd $dir/certificate-authority/certificate && ./reset.sh
cd $dir/certificate-authority/tls && ./reset.sh

cd $dir/network
./reset.sh

cd $dir
