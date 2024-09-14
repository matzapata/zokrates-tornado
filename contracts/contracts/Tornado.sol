// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./Verifier.sol";

import "hardhat/console.sol";

contract MerkleTreeWithHistory {
    bytes32[] public tree; // Flattened Merkle tree
    uint256 public maxLeaves; // Maximum number of leaves

    constructor(uint256 _maxLeaves) {
        require(_maxLeaves > 0, "Max leaves must be greater than 0");
        maxLeaves = _maxLeaves;
        
        uint256 initialSize = 2 * _maxLeaves - 1;
        for (uint256 i = 0; i < initialSize; i++) {
            tree.push(bytes32(0));
        }
    }

    function _insert(bytes32 leaf) public returns (uint256) {
        require(tree.length >= maxLeaves, "Tree not initialized properly");

        uint256 leafIndex = maxLeaves - 1; // Starting index for leaves
        for (uint256 i = 0; i < maxLeaves; i++) {
            if (tree[leafIndex] == bytes32(0)) {
                tree[leafIndex] = leaf;
                break;
            }
            leafIndex++;
        }

        uint256 currentIndex = leafIndex;
        while (currentIndex > 0) {
            uint256 parentIndex = (currentIndex - 1) / 2;
            uint256 leftChild = 2 * parentIndex + 1;
            uint256 rightChild = 2 * parentIndex + 2;

            bytes32 leftHash = (leftChild < tree.length) ? tree[leftChild] : bytes32(0);
            bytes32 rightHash = (rightChild < tree.length) ? tree[rightChild] : bytes32(0);
            
            tree[parentIndex] = sha256(abi.encodePacked(leftHash, rightHash));
            currentIndex = parentIndex;
        }

        return currentIndex;
    }

    function _root() public view returns (bytes32) {
        return tree[0];
    }
}


contract Tornado is MerkleTreeWithHistory, Verifier {
    uint256 public denomination;

    mapping(bytes32 => bool) public nullifierHashes;

    event Deposit(bytes32 _commitment, uint256 _index, uint256 _timestamp); // required to rebuild the merkle tree by the user
    event Withdrawal(address to, bytes32 nullifierHash);

    constructor(uint256 _denomination) MerkleTreeWithHistory(2) {
        denomination = _denomination;
    }

    // collect native, insert in the merkle tree and emit event to allow for reconstruction of merkle tree
    // _commitment = hash(nullifier + secret)
    function deposit(bytes32 _commitment) external payable {
        require(
            msg.value == denomination,
            "Wrong denomination. All deposits should be equal amount"
        );

        uint256 insertedIndex = _insert(_commitment);

        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    // avoid double spending by checking nullifier was spend or not
    // check proof with merkle tree, verify proof and transfer funds
    function withdraw(
        Proof memory _proof,
        bytes32 _root, // can't I link root update with tx that updated it and therefore know commitment?
        bytes32 _nullifierHash,
        address payable _recipient
    ) external {
        require(
            !nullifierHashes[_nullifierHash],
            "The note has been already spent"
        );
        // require(_isKnownRoot(_root), "Cannot find your merkle root");
        require(
            verifyTx(_proof, _assembleProofInput(_root, _nullifierHash)),
            "Invalid withdraw proof"
        );

        nullifierHashes[_nullifierHash] = true;

        _recipient.transfer(denomination);

        emit Withdrawal(_recipient, _nullifierHash);
    }

    function isSpent(bytes32 _nullifierHash) public view returns (bool) {
        return nullifierHashes[_nullifierHash];
    }

    function _assembleProofInput(
        bytes32 _root,
        bytes32 _nullifierHash
    ) internal pure returns (uint[17] memory) {
        uint[17] memory _input;

        // Extract 4 bytes (32 bits) from _root and _nullifier into _input
        for (uint256 i = 0; i < 8; i++) {
            _input[i] = uint256(uint32(bytes4(_root << (32 * i)))); // Extract 4 bytes (32 bits)
            _input[i + 8] = uint256(uint32(bytes4(_nullifierHash << (32 * i)))); // Extract 4 bytes (32 bits)
        }

        return _input;
    }
}
