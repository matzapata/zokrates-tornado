// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "./Verifier.sol";
import "./MerkleTreeWithHistory.sol";

contract Tornado is MerkleTreeWithHistory, Verifier {
    uint256 public denomination;

    mapping(bytes32 => bool) public nullifierHashes;

    event Deposit(bytes32 _commitment, uint256 _index, uint256 _timestamp); // required to rebuild the merkle tree by the user
    event Withdrawal(address to, bytes32 nullifierHash);

    constructor(
        uint256 _denomination,
        uint32 _levels,
        IHasher _hasher
    ) MerkleTreeWithHistory(_levels, _hasher) {
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
        require(!isKnownRoot(_root), "Cannot find your merkle root");
        require(
            verifyTx(_proof, [uint256(_root), uint256(_nullifierHash)]),
            "Invalid withdraw proof"
        );

        nullifierHashes[_nullifierHash] = true;

        _recipient.transfer(denomination);

        emit Withdrawal(_recipient, _nullifierHash);
    }

    function isSpent(bytes32 _nullifierHash) public view returns (bool) {
        return nullifierHashes[_nullifierHash];
    }
}
