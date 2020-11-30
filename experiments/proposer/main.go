package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path"
	"time"

	shell "github.com/ipfs/go-ipfs-api"
)

var defaultDuration time.Duration

func init() {
	var err error
	defaultDuration, err = time.ParseDuration("25ms")
	if err != nil {
		panic(err)
	}
}
func main() {
	leavesDir := flag.String("leaf-files", "testfiles/leaves", "Directory paths to leaf files (named 0.json, 1.json, ..., n.json)")
	// ipfsURL := flag.String("ipfs-url", "localhost:5001", "IPFS URL to use locally")
	numTrees := flag.Int("num-trees", 100, "number of trees to generate")

	// TODO: find out if it makes a difference if the proposer node puts all trees to the (local) DAG at once.
	// If not, the parameter might not be necessary.
	blockTime := flag.Duration("block-time", defaultDuration, "'Propose' new 'block' every block-time duration (default 250ms). Essentially, adds a tree to the local DAG. Accepts any valid input for time.ParseDuration.")

	flag.Parse()

	sh := shell.NewShell("localhost:5001")
	for treeIter := 0; treeIter < *numTrees; treeIter++ {
		leafFile := path.Join(*leavesDir, fmt.Sprintf("%v.json", treeIter))
		d, err := ioutil.ReadFile(leafFile)
		if err != nil {
			panic(err)
		}
		cid, err := sh.DagPut(d, "json", "merkle-leaves")
		if err != nil {
			fmt.Fprintf(os.Stderr, "error while putting into dag: %s.\nShutting down proposer...", err)
			os.Exit(1)
		}

		log.Printf("added %s\n", cid)

		time.Sleep(*blockTime)
	}

}
