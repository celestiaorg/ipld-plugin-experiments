package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"os"
	"strings"
	"time"

	"github.com/pkg/errors"

	shell "github.com/ipfs/go-ipfs-api"

	"github.com/liamsi/ipld-plugin-experiments/merkle-tree"
)

var binFormattingMap = map[int]string{
	2:   "%01b",
	4:   "%02b",
	8:   "%03b",
	16:  "%04b",
	32:  "%05b",
	64:  "%06b",
	128: "%07b",
	256: "%08b",
}

func main() {
	cidFile := flag.String("cids-file", "testfiles/cids.json", "File with the CIDs (tree roots) to sample paths for.")
	numLeaves := flag.Int("num-leaves", 32, "Number of leaves. Will be used to determine the paths to sample.")
	numSamples := flag.Int("num-samples", 15, "Number of samples per block/tree. Each sample will run in a go-routine.")

	flag.Parse()

	if _, ok := binFormattingMap[*numLeaves]; !ok {
		fmt.Fprintf(os.Stderr, "Invalid number of leaves. Should be a power of two <= 256.\nShutting down client...")
		os.Exit(1)
	}

	cids := make([]string, 0)
	cidsBytes, err := ioutil.ReadFile(*cidFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error while reading CIDs file: %s.\nShutting down client...", err)
		os.Exit(1)
	}
	err = json.Unmarshal(cidsBytes, &cids)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error while parsing CIDs file: %s.\nShutting down client...", err)
		os.Exit(1)
	}
	log.Println("Sleep some time before the first sample request ...")
	time.Sleep(10 * time.Second)
	log.Println(" ... and we are back. Starting sampling")

	sh := shell.NewLocalShell()
	if sh == nil {
		log.Println("ipfs is not running properly. Shutting down...")
		os.Exit(1)
	}
	for _, cid := range cids {
		resChan := make(chan Result, *numSamples)
		for sampleIter := 0; sampleIter < *numSamples; sampleIter++ {
			go func() {
				path := generateRandPath(cid, *numLeaves)
				ln := &merkle.LeafNode{}

				now := time.Now()
				err = sh.DagGet(path, ln)
				if err != nil {
					log.Println(Result{Err: errors.Wrap(err, fmt.Sprintf("could no get %s from dag", path))})
					resChan <- Result{Err: errors.Wrap(err, fmt.Sprintf("could no get %s from dag", path))}
				} else {
					elapsed := time.Since(now)
					resChan <- Result{Elapsed: elapsed}

					log.Printf("DagGet %s took: %v\n", path, elapsed)
				}

			}()
		}
		beforeSamples := time.Now()
		for i := 0; i < *numSamples; i++ {
			select {
			case msg1 := <-resChan:
				// TODO collect single results in array
				log.Println("received", msg1)
			}
		}
		elapsedDAProof := time.Since(beforeSamples)
		log.Printf("DA proof for cid %s took: %v\n", cid, elapsedDAProof)

		// TODO write all data into files

		fmt.Println("sleep in between rounds...")
		time.Sleep(30 * time.Second)
	}
}

func generateRandPath(cid string, numLeaves int) string {
	idx := rand.Intn(numLeaves)
	fmtDirective := binFormattingMap[numLeaves]
	bin := fmt.Sprintf(fmtDirective, idx)
	path := strings.Join(strings.Split(bin, ""), "/")
	return cid + "/" + path
}

type Result struct {
	Elapsed time.Duration
	Err     error
}
