// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./Verifier.sol";

contract Demo is Verifier {
    function doSomethingIfValid(
        Proof memory proof,
        uint[1] memory input
    ) public view returns (bool) {
        require(verifyTx(proof, input), "Invalid proof");

        // Do smth
        return true;
    }
}
