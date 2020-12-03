#!/usr/bin/env bash

set -e

default_rounds=100
default_leaves=32

NUM_ROUNDS=${1:-$default_rounds}
NUM_LEAVES=${2:-$default_leaves}
OUT_DIR=${3:-"~/ipfs-experiments/measurements"}


echo "We are not 'proposer'. Starting client: $MY_NAME"
cd /tmp/ipld-plugin-experiments
go run experiments/clients/main.go -cids-file=/var/local/testfiles/cids.json -num-leaves=$NUM_LEAVES -out-dir=$OUT_DIR
