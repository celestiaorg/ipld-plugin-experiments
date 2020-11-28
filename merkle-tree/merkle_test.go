package merkle

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"testing"
)

var regenerate = true

func TestGenerateTwoLeafJSON(t *testing.T) {
	leafs := jsonLeaves{Leaves: []Share{{Data: []byte("leaf1")}, {Data: []byte("leaf2")}}}

	res, err := json.Marshal(leafs)
	if err != nil {
		panic(err)
	}
	os.Stdout.Write(res)
}

func TestGenerateJSONFiles(t *testing.T) {
	if !regenerate {
		t.Skip("Skipping regenerating test files")
	}
	tcs := []struct {
		name      string
		iters     int
		numLeaves int
	}{
		{"32", 100, 32},
		//{"256", 100, 256},
	}
	for _, tc := range tcs {
		for iter := 0; iter < tc.iters; iter++ {
			leafs := generateLeavesJSON(tc.numLeaves)

			res, err := json.Marshal(leafs)
			if err != nil {
				t.Fatalf("unexpected err while marshaling: %s", err)
			}

			if err := ioutil.WriteFile(fmt.Sprintf("../testfiles/%s_%v.json", tc.name, iter), res, 0644); err != nil {
				t.Fatalf("could not write test file: %v", err)
			}
		}
	}
}

func generateLeavesJSON(num int) *jsonLeaves {
	var leafLength = 256
	leavesData := make([]Share, num)
	for i := 0; i < len(leavesData); i++ {
		data := make([]byte, leafLength)
		rand.Read(data)
		leavesData[i] = Share{Data: data}
	}
	return &jsonLeaves{Leaves: leavesData}
}
