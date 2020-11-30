package main

import (
	"crypto/rand"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/liamsi/ipld-plugin-experiments/merkle-tree"
)

func main() {
	outDir := flag.String("output", "testfiles", "output directory")
	numLeaves := flag.Int("num-leaves", 2, "number of leaves")
	numTrees := flag.Int("num-trees", 100, "number of trees to generate")
	flag.Parse()

	if _, err := os.Stat(*outDir); os.IsNotExist(err) {
		os.Mkdir(*outDir, os.ModePerm)
	}
	leavesDir := *outDir + "/leaves"
	if _, err := os.Stat(leavesDir); os.IsNotExist(err) {
		os.Mkdir(leavesDir, os.ModePerm)
	}

	cids := make([]string, *numTrees)
	for iter := 0; iter < *numTrees; iter++ {
		leafs := generateLeavesJSON(*numLeaves)

		res, err := json.Marshal(leafs)
		if err != nil {
			panic(fmt.Sprintf("unexpected err while marshaling: %s", err))
		}

		if err := ioutil.WriteFile(fmt.Sprintf("%s/%v.json", leavesDir, iter), res, 0644); err != nil {
			panic(fmt.Sprintf("could not write test file: %v", err))
		}
		input := make([][]byte, *numLeaves)
		for i, l := range leafs.Leaves {
			input[i] = l.Data
		}
		_, nodes := merkle.ComputeNodes(input)
		// assert that root and CID match
		cids[iter] = nodes[0].Cid().String()
	}

	res, err := json.Marshal(cids)
	if err != nil {
		panic(fmt.Sprintf("unexpected err while marshaling: %s", err))
	}

	if err := ioutil.WriteFile(fmt.Sprintf("%s/cids.json", *outDir), res, 0644); err != nil {
		panic(fmt.Sprintf("could not write test file: %v", err))
	}

	log.Println("Done generating testfiles.")
	log.Printf("Generated %v trees with %v leafs.\n", *numTrees, *numLeaves)
}

func generateLeavesJSON(num int) *merkle.JsonLeaves {
	var leafLength = 256
	leavesData := make([]merkle.Share, num)
	for i := 0; i < len(leavesData); i++ {
		data := make([]byte, leafLength)
		rand.Read(data)
		leavesData[i] = merkle.Share{Data: data}
	}
	return &merkle.JsonLeaves{Leaves: leavesData}
}
