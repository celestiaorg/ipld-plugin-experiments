#!/usr/bin/env bash

set -e
default_rounds=100

NUM_ROUNDS=${1:-$default_rounds}

source ~/.profile

echo "Add trees to local DAG."
cd /tmp/ipld-plugin-experiments
go run experiments/proposer/main.go -leaf-files=/var/local/testfiles/leaves -num-trees=$NUM_ROUNDS
