package merkle

import (
	"encoding/json"
	"os"
	"testing"
)

func TestGenerateTwoLeafJSON(t *testing.T) {
	leafs := jsonLeaves{Leaves: []Share{{Data: []byte("leaf1")}, {Data: []byte("leaf2")}}}

	res, err := json.Marshal(leafs)
	if err != nil {
		panic(err)
	}
	os.Stdout.Write(res)
}
