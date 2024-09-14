// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./Verifier.sol";

import "hardhat/console.sol";

contract Demo is Verifier {
    function doSomethingIfValid(
        Proof memory _proof,
        bytes32 _root,
        bytes32 _nullifier
    ) public view returns (bool) {
        require(
            verifyTx(_proof, _formatProofInput(_root, _nullifier)),
            "Invalid proof"
        );

        console.log("Doing smth...");

        // Do smth
        return true;
    }

    function _formatProofInput(
        bytes32 _root,
        bytes32 _nullifier
    ) internal pure returns (uint[17] memory) {
        uint[17] memory _input;

        // Extract 4 bytes (32 bits) from _root and _nullifier into _input
        for (uint256 i = 0; i < 8; i++) {
            _input[i] = uint256(uint32(bytes4(_root << (32 * i)))); // Extract 4 bytes (32 bits)
            _input[i + 8] = uint256(uint32(bytes4(_nullifier << (32 * i)))); // Extract 4 bytes (32 bits)
        }

        return _input;
    }

    function verifyMerkleTree(
        bytes32 _root,
        bytes32 _documentHash,
        bytes32[] calldata _proof
    ) public pure returns (bool) {
        bytes32 current = _documentHash;
        for (uint256 i = 0; i < _proof.length; i++) {
            bytes32 proofElement = _proof[i];
            if (current < proofElement) {
                current = sha256(abi.encodePacked(current, proofElement));
            } else {
                current = sha256(abi.encodePacked(proofElement, current));
            }
        }
        return current == _root;
    }
}
