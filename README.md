# ipld-plugin-experiments

This repository contains the following:

* merkle (go package): a quickly hacked ipld plugin that uses a very simple merkle tree as a dag to store leaves.
* terraform: terraform scripts to run experiments on DigitalOcean

**NOTE:** All packages and tools in this repository are highly experimental. Their only purpose is to run cloud-based simulations.

There are essentially two simulations/measurements:
 1) Measure latency for data availability proofs for a freshly proposed "block" (defaults to 15 random samples in parallel).
 2) Measure time for a fresh client to sync n "blocks" (trees) in parallel from a cluster of nodes that have already seen and validated the block (via DA proofs).  

## Run the experiments

TODO short intro; see readme in [terraform](terraform/Readme.md). 

## Building and Installing the ipld-plugin

**Note**: Below steps are not necessary to follow for running the experiments. 
Test files will be generated on the machine running terraform without installing the plugin.  

You can *build* the example plugin by running `make build`. You can then install it into your local IPFS repo by running `make install`.

Plugins need to be built against the correct version of go-ipfs. This package generally tracks the latest go-ipfs release but if you need to build against a different version, please set the `IPFS_VERSION` environment variable.

You can set `IPFS_VERSION` to:

* `vX.Y.Z` to build against that version of IPFS.
* `$commit` or `$branch` to build against a specific go-ipfs commit or branch.
   * Note: if building against a commit or branch make sure to build that commit/branch using the -trimpath flag. For example getting the binary via `go get -trimpath github.com/ipfs/go-ipfs/cmd/ipfs@COMMIT`
* `/absolute/path/to/source` to build against a specific go-ipfs checkout.

To update the go-ipfs, run:

```bash
> make go.mod IPFS_VERSION=version
```

## License

MIT
