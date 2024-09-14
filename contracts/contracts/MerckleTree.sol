// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

contract MerkleProof {
    bytes32 public merkleRoot;
    uint256 public leafCount;
    mapping(uint256 => bytes32) public leaves;
    

    constructor(bytes32 _root) {
        merkleRoot = _root;
    }

    function insert(bytes32 leaf) public {
        leaves[leafCount] = leaf;
        leafCount++;

        // assemble leaf arrat from leaf map
        bytes32[] memory leafArray = new bytes32[](leafCount);
        for (uint256 i = 0; i < leafCount; i++) {
            leafArray[i] = leaves[i];
        }
        if (leafArray.length == 0) {
            revert("No leaves to insert");
        }

        // compute the root hash
        while (leafArray.length > 1) {
            uint256 nextLevel = 0;
            for (uint256 i = 0; i < leafArray.length; i += 2) {
                if (i + 1 < leafArray.length) {
                    // Always concatenate the left node first, followed by the right node
                    leafArray[nextLevel] = keccak256(
                        abi.encodePacked(leafArray[i], leafArray[i + 1])
                    );
                } else {
                    // Odd number of leaves, promote last leaf
                    leafArray[nextLevel] = leafArray[i];
                }

                nextLevel++;
            }

            assembly {
                mstore(leafArray, nextLevel) // Resize array to next level size
            }
        }

        merkleRoot = leafArray[0]; // The root
    }

    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            computedHash = keccak256(
                abi.encodePacked(computedHash, proofElement)
            );
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function getRoot() public view returns (bytes32) {
        return merkleRoot;
    }
}
