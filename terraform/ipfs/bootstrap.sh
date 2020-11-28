#!/usr/bin/env bash

set -e

IPFS_VERSION=0.7.0

# Wait for cloud-init to complete
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# install some core deps
apt update
apt install -y \
  bc \
  build-essential \
  git \
  jq

# install golang 1.15.5
cd /tmp
curl -O https://dl.google.com/go/go1.15.5.linux-amd64.tar.gz
tar -xvf go1.15.5.linux-amd64.tar.gz

## move binary and add to path
mv go /usr/local
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
git checkout "tags/v${IPFS_VERSION} -b ${IPFS_VERSION}"
make install
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

exit 0