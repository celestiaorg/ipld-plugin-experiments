package merkle

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math/bits"

	blocks "github.com/ipfs/go-block-format"
	"github.com/ipfs/go-cid"
	"github.com/ipfs/go-ipfs/core/coredag"
	"github.com/ipfs/go-ipfs/plugin"
	node "github.com/ipfs/go-ipld-format"
	coreiface "github.com/ipfs/interface-go-ipfs-core"
	mh "github.com/multiformats/go-multihash"
)

type TreePlugin struct{}

func (t TreePlugin) Start(api coreiface.CoreAPI) error {
	fmt.Println("TreePlugin loaded")
	return nil
}

var _ plugin.PluginIPLD = (*TreePlugin)(nil)
var _ plugin.PluginDaemon = (*TreePlugin)(nil)

// 0x87 seems to be free:
// https://github.com/multiformats/multicodec/blob/master/table.csv
const Tree = 0x87

func (t TreePlugin) Name() string {
	return "ipld-Merkle"
}

func (t TreePlugin) Version() string {
	return "0.0"
}

func (t TreePlugin) Init(env *plugin.Environment) error {
	return nil
}

func (t TreePlugin) RegisterInputEncParsers(iec coredag.InputEncParsers) error {
	iec.AddParser("json", "merkle-leaves", TreeLeavesJSONInputParser)
	return nil
}

func (t TreePlugin) RegisterBlockDecoders(dec node.BlockDecoder) error {
	dec.Register(Tree, TreeNodeParser)
	return nil
}

func TreeNodeParser(block blocks.Block) (node.Node, error) {
	data := block.RawData()
	if len(data) == 0 {
		return &LeafNode{
			RawHash: emptyHash(),
			Data:    nil,
		}, nil
	}
	firstByte := data[:1]
	if bytes.Equal(firstByte, leafPrefix) {
		h := block.Cid().Hash()
		return &LeafNode{
			RawHash: h[2:], // CID().Hash() returns hash-code||len(hash)||hash
			Data:    data[1:],
		}, nil
	} else if bytes.Equal(firstByte, innerPrefix) {
		h := block.Cid().Hash()
		return InnerNode{
			rawHash: h[2:], // CID().Hash() returns hash-code||len(hash)||hash
			l:       data[1:33],
			r:       data[33:],
		}, nil
	}
	return nil, errors.New("unknown err")
}

func TreeLeavesJSONInputParser(r io.Reader, _mhType uint64, _mhLen int) ([]node.Node, error) {
	// this can be anything; just using JSON as it's easy to understand
	// what's fed into the tree:
	shares, err := parseSharesFromJSON(r)
	if err != nil {
		return nil, err
	}

	input := make([][]byte, len(shares))
	for i, share := range shares {
		input[i] = share.Data
	}
	_, nodes := ComputeNodes(input)
	fmt.Println(fmt.Sprintf("length of nodes: %d", len(nodes)))
	return nodes, nil

}

type InnerNode struct {
	rawHash []byte
	l, r    []byte
}

func (i InnerNode) RawData() []byte {
	// fmt.Sprintf("inner-node-Data: %#v\n", append(innerPrefix, append(i.l, i.r...)...))
	return append(innerPrefix, append(i.l, i.r...)...)
}

func (i InnerNode) Cid() cid.Cid {
	// fmt.Sprintf("inner-node-cid: %#v\n", cidFromSha256(i.RawHash))
	return cidFromSha256(i.rawHash)
}

func cidFromSha256(rawHash []byte) cid.Cid {
	buf, err := mh.Encode(rawHash, mh.SHA2_256)
	if err != nil {
		panic(err)
	}

	return cid.NewCidV1(Tree, mh.Multihash(buf))
}

func (i InnerNode) String() string {
	return fmt.Sprintf(`
inner-node {
	hash: %x, 
	l: %x, 
	r: %x"
}`, i.rawHash, i.l, i.r)
}

func (i InnerNode) Loggable() map[string]interface{} {
	return nil
}

func (i InnerNode) Resolve(path []string) (interface{}, []string, error) {
	switch path[0] {
	case "0":
		return &node.Link{Cid: cidFromSha256(i.l)}, path[1:], nil
	case "1":
		return &node.Link{Cid: cidFromSha256(i.r)}, path[1:], nil
	default:
		return nil, nil, errors.New("invalid path for inner node")
	}

}

func (i InnerNode) Tree(path string, depth int) []string {
	if path != "" || depth == 0 {
		return nil
	}

	return []string{
		"0",
		"1",
	}
}

func (i InnerNode) ResolveLink(path []string) (*node.Link, []string, error) {
	obj, rest, err := i.Resolve(path)
	if err != nil {
		return nil, nil, err
	}

	lnk, ok := obj.(*node.Link)
	if !ok {
		return nil, nil, fmt.Errorf("was not a link")
	}

	return lnk, rest, nil
}

func (i InnerNode) Copy() node.Node {
	panic("implement me")
}

func (i InnerNode) Links() []*node.Link {
	return []*node.Link{{Cid: cidFromSha256(i.l)}, {Cid: cidFromSha256(i.r)}}
}

func (i InnerNode) Stat() (*node.NodeStat, error) {
	return &node.NodeStat{}, nil
}

func (i InnerNode) Size() (uint64, error) {
	return 0, nil
}

type LeafNode struct {
	RawHash []byte
	Data    []byte
}

func (l LeafNode) RawData() []byte {
	return append(leafPrefix, l.Data...)
}

func (l LeafNode) Cid() cid.Cid {
	buf, err := mh.Encode(l.RawHash, mh.SHA2_256)
	if err != nil {
		panic(err)
	}
	cidV1 := cid.NewCidV1(Tree, mh.Multihash(buf))
	return cidV1
}

func (l LeafNode) String() string {
	return fmt.Sprintf(`
leaf-node {
	hash: 		%x,
	len(Data): 	%v
}`, l.RawHash, len(l.Data))
}

func (l LeafNode) Loggable() map[string]interface{} {
	return nil
}

func (l LeafNode) Resolve(path []string) (interface{}, []string, error) {
	if path[0] == "Data" {
		// TODO: store the data separately
		// currently Leaf{Data:} contains the actual data
		// instead there should be a link in the leaf to the actual data
		return nil, nil, nil
	} else {
		return nil, nil, errors.New("invalid path for leaf node")
	}
}

func (l LeafNode) Tree(path string, depth int) []string {
	if path != "" || depth == 0 {
		return nil
	}

	return []string{
		"Data",
	}
}

func (l LeafNode) ResolveLink(path []string) (*node.Link, []string, error) {
	obj, rest, err := l.Resolve(path)
	if err != nil {
		return nil, nil, err
	}

	lnk, ok := obj.(*node.Link)
	if !ok {
		return nil, nil, fmt.Errorf("was not a link")
	}

	return lnk, rest, nil
}

func (l LeafNode) Copy() node.Node {
	panic("implement me")
}

func (l LeafNode) Links() []*node.Link {
	return []*node.Link{{Cid: l.Cid()}}
}

func (l LeafNode) Stat() (*node.NodeStat, error) {
	return &node.NodeStat{}, nil
}

func (l LeafNode) Size() (uint64, error) {
	return 0, nil
}

var _ node.Node = (*InnerNode)(nil)
var _ node.Node = (*LeafNode)(nil)

type Share struct {
	// TODO add namespace.ID
	Data []byte
}

type JsonLeaves struct {
	Leaves []Share
}

func parseSharesFromJSON(r io.Reader) ([]Share, error) {
	var obj JsonLeaves
	dec := json.NewDecoder(r)
	err := dec.Decode(&obj)
	if err != nil {
		return nil, err
	}
	return obj.Leaves, nil
}

// ---- recursively compute the nodes (RFC-6962); used tendermint's implementation as a basis ---- //

func ComputeNodes(items [][]byte) ([]byte, []node.Node) {
	switch len(items) {
	case 0:
		emptyHash := emptyHash()
		return emptyHash, []node.Node{&LeafNode{
			RawHash: emptyHash,
			Data:    nil,
		}}
	case 1:
		hash := leafHash(items[0])
		return hash, []node.Node{&LeafNode{
			RawHash: hash,
			Data:    items[0],
		}}
	default:
		k := getSplitPoint(int64(len(items)))
		left, lnodes := ComputeNodes(items[:k])
		right, rnodes := ComputeNodes(items[k:])
		parentHash := innerHash(left, right)
		parentNode := []node.Node{&InnerNode{
			rawHash: parentHash,
			l:       left,
			r:       right,
		}}
		return parentHash, append(parentNode, append(lnodes, rnodes...)...)
	}
}

func getSplitPoint(length int64) int64 {
	if length < 1 {
		panic("Trying to split a tree with size < 1")
	}
	uLength := uint(length)
	bitlen := bits.Len(uLength)
	k := int64(1 << uint(bitlen-1))
	if k == length {
		k >>= 1
	}
	return k
}

var (
	leafPrefix  = []byte{0}
	innerPrefix = []byte{1}
)

func emptyHash() []byte {
	h := sha256.New()
	h.Write(nil)
	return h.Sum(nil)
}

func leafHash(leaf []byte) []byte {
	h := sha256.New()
	h.Write(append(leafPrefix, leaf...))
	return h.Sum(nil)
}

func innerHash(left []byte, right []byte) []byte {
	h := sha256.New()
	h.Write(append(innerPrefix, append(left, right...)...))
	return h.Sum(nil)
}
