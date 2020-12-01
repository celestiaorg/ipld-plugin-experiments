#!/usr/bin/env bash

set -e

default_rounds=100
default_leaves=32
# Take in the hostname of the 'proposer' -  the node that adds the whole tree DAG locally
PROPOSER=$1
NUM_ROUNDS=${2:-$default_rounds}
NUM_LEAVES=${3:-$default_leaves}
OUT_DIR=${4:-"/var/local/measurements"}

IPFS_VERSION=0.7.0

# Wait for cloud-init to complete
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# install some core deps
apt update
apt install -y \
  build-essential \
  git \
  jq

# install golang 1.15.5
cd /tmp
curl -O https://dl.google.com/go/go1.15.5.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.15.5.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile

## create the goApps directory, set GOPATH, and put it on PATH
mkdir goApps
echo "export GOPATH=/root/goApps" >> ~/.profile
echo "export PATH=\$PATH:\$GOPATH/bin" >> ~/.profile
# **turn on the go module, default is auto. The value is off, if tendermint source code
#is downloaded under $GOPATH/src directory
echo "export GO111MODULE=on" >> ~/.profile

source ~/.profile

# Install IPFS
cd /tmp
git clone https://github.com/ipfs/go-ipfs.git
cd go-ipfs
git checkout tags/v${IPFS_VERSION} -b v${IPFS_VERSION}
make install
cp $GOPATH/bin/ipfs /usr/local/bin
# This would be faster than the above but we'll bump into: https://github.com/golang/go/issues/27751
# wget "https://dist.ipfs.io/go-ipfs/v${IPFS_VERSION}/go-ipfs_v${IPFS_VERSION}_linux-amd64.tar.gz"
# tar xvfz "go-ipfs_v${IPFS_VERSION}_linux-amd64.tar.gz"
# cp go-ipfs/ipfs /usr/local/bin


# Install plugin
cd /tmp
git clone https://github.com/liamsi/ipld-plugin-experiments.git
cd ipld-plugin-experiments
./set-target.sh /tmp/go-ipfs/
make install
cd ~

# Configure IPFS
ipfs init
cp -f /tmp/ipfs/ipfs.service /etc/systemd/system/ipfs.service
systemctl daemon-reload
systemctl enable ipfs
systemctl start ipfs

# Wait for IPFS daemon to start
sleep 10
until [[ `ipfs id >/dev/null 2>&1; echo $?` -eq 0 ]]; do
  sleep 1
done
sleep 10

MY_NAME=$(hostname)
if [ $MY_NAME == $PROPOSER ]; then
  echo "We are 'proposer'. Add trees to local DAG."
  cd /tmp/ipld-plugin-experiments
  go run experiments/proposer/main.go -leaf-files=/var/local/testfiles/leaves -num-trees=$NUM_ROUNDS
else
  echo "We are not 'proposer'. Starting client: $MY_NAME"
  cd /tmp/ipld-plugin-experiments
  go run experiments/clients/main.go -cids-file=/var/local/testfiles/cids.json -num-leaves=$NUM_LEAVES -out-dir=$OUT_DIR
fi


exit 0