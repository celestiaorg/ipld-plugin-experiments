package main

import (
	"github.com/ipfs/go-ipfs-example-plugin/merkle-tree"
	"github.com/ipfs/go-ipfs/plugin"

	greeter "github.com/ipfs/go-ipfs-example-plugin/greeter"
)

// Plugins is an exported list of plugins that will be loaded by go-ipfs.
var Plugins = []plugin.Plugin{
	//&delaystore.DelaystorePlugin{},
	&greeter.GreeterPlugin{}, // keep to see if this is actually loaded
	&merkle.TreePlugin{},
}
