#!/bin/bash
set -e

dir=$PWD

cd $dir/root-ca/certificate && ./reset.sh
cd $dir/root-ca/tls && ./reset.sh

cd $dir
