package merkle

import (
	"encoding/json"
	"fmt"
	"os"
	"testing"

	"github.com/ipfs/go-cid"
)

func TestCreateJSON(t *testing.T) {
	leafs := jsonLeaves{Leaves: []Share{{Data: []byte("leaf1")}, {Data: []byte("leaf2")}}}

	res, err := json.Marshal(leafs)
	if err != nil {
		panic(err)
	}
	os.Stdout.Write(res)

	c, err := cid.Decode("bafkre3ibabwgkylgghr3brcctd6byfe27p2mrglpxescplsb4rsjxe2muskzsg3ykk4fkadmmvqwmmxdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvykxr3brcctd6byfe27p2mrglpxescplsb4rsjxe2muskzsg3ykk4fk")
	if err != nil {
		panic(err)
	}

	fmt.Printf("\nGot CID: %#v", c.Prefix())

}
