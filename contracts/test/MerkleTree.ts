import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import MerkleTree from "merkletreejs";
import crypto from "crypto"
import keccak256 from "keccak256";


describe("DynamicMerkleTree", function () {
  async function deployFixture() {
    const Tree = await hre.ethers.getContractFactory("MerkleProof");
    const tree = await Tree.deploy(keccak256(0))

    return { tree, Tree };
  }


  it('should return true for valid merkle proof (example)', async () => {
    const { tree: contract  } = await loadFixture(deployFixture)

    const leaves = ['a', 'b', 'c', 'd'].map(v => keccak256(v))
    const tree = new MerkleTree(leaves, keccak256, { sort: false })
    const root = tree.getHexRoot()
    const leaf = keccak256('a')
    const proof = tree.getHexProof(leaf)

    const verified = await contract.verify(root, leaf, proof)
    expect(verified).to.equal(true)

    const badLeaves = ['a', 'b', 'x', 'd'].map(v => keccak256(v))
    const badTree = new MerkleTree(badLeaves, keccak256, { sort: false })
    const badProof = badTree.getHexProof(leaf)

    const badVerified = await contract.verify(root, leaf, badProof)
    expect(badVerified).to.equal(false)
  })

  it("anc",  async () => {
    const { tree: contract  } = await loadFixture(deployFixture)

    const leaves = ['a', 'b', 'c', 'd'].map(v => keccak256(v))
    const tree = new MerkleTree(leaves, keccak256, { sort: false })
    const root = tree.getHexRoot()

    await contract.insert(leaves[0]);
    await contract.insert(leaves[1]);
    await contract.insert(leaves[2]);
    await contract.insert(leaves[3]);

    const r = await contract.getRoot()
    console.log("r", r, root)

    expect(root).to.equal(r)
  })

  // it('should return false for invalid merkle proof', async () => {
  //   const leaves = ['a', 'b', 'c', 'd'].map(v => keccak256(v))
  //   const tree = new MerkleTree(leaves, keccak256, { sort: true })
  //   const root = buf2hex(tree.getRoot())
  //   const leaf = buf2hex(keccak256('b'))

  //   const badLeaves = ['a', 'b', 'c', 'x'].map(v => keccak256(v))
  //   const badTree = new MerkleTree(badLeaves, keccak256)
  //   const badProof = badTree.getProof(keccak256('b')).map(x => buf2hex(x.data))

  //   const verified = await contract.verify.call(root, leaf, badProof)
  //   assert.equal(verified, false)
  // })

  // it('should return false for a merkle proof of invalid length', async () => {
  //   const leaves = ['a', 'b', 'c'].map(v => keccak256(v))
  //   const tree = new MerkleTree(leaves, keccak256, { sort: true })
  //   const root = buf2hex(tree.getRoot())
  //   const leaf = buf2hex(keccak256('c'))
  //   const proof = tree.getProof(keccak256('c'))
  //   const badProof = proof.slice(0, proof.length-2).map(x => buf2hex(x.data))

  //   const verified = await contract.verify.call(root, leaf, badProof)
  //   assert.equal(verified, false)
  // })

  // it('should return true for valid merkle proof (SO#63509)', async () => {
  //   const leaves = ['0x00000a86986e8ba3557992df02883e4a646e8f25 50000000000000000000', '0x00009c99bffc538de01866f74cfec4819dc467f3 75000000000000000000', '0x00035a5f2c595c3bb53aae4528038dd7a85641c3 50000000000000000000', '0x1e27c325ba246f581a6dcaa912a8e80163454c75 10000000000000000000'].map(v => keccak256(v))
  //   const tree = new MerkleTree(leaves, keccak256, { sort: true })
  //   const root = tree.getRoot()
  //   const hexroot = buf2hex(root)
  //   const leaf = keccak256('0x1e27c325ba246f581a6dcaa912a8e80163454c75 10000000000000000000')
  //   const hexleaf = buf2hex(leaf)
  //   const proof = tree.getProof(leaf)
  //   const hexproof = tree.getProof(leaf).map(x => buf2hex(x.data))

  //   const verified = await contract.verify.call(hexroot, hexleaf, hexproof)
  //   assert.equal(verified, true)

  //   assert.equal(tree.verify(proof, leaf, root), true)
  // })
});
