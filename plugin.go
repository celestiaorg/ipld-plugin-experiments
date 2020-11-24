package main

import (
	"github.com/ipfs/go-ipfs/plugin"

	"github.com/liamsi/ipld-plugin-experiments/merkle-tree"
)

// Plugins is an exported list of plugins that will be loaded by go-ipfs.
var Plugins = []plugin.Plugin{
	&merkle.TreePlugin{},
}
