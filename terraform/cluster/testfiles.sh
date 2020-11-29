#!/usr/bin/env bash

set -e

default_out=./testfiles
default_leaves=32
default_rounds=100

OUT_DIR=${1:-$default_out}
NUM_LEAVES=${2:-$default_leaves}
NUM_ROUNDS=${3:-$default_rounds}

echo 'generating testfiles'
go run ../experiments/generate/generate.go -output=$OUT_DIR -num-leaves=$NUM_LEAVES -num-trees=$NUM_ROUNDS