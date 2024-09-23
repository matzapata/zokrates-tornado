
# Zokrates Tornado

A simple implementation of tornado to showcase zokrates.

Commands:

- `make compile` -> Compiles circuits and contracts
- `make compile-circuits` -> Compile circuits and generate fixture for tests
- `make compile-contracts` -> Compile contracts
- `make tests` -> runs tests

Details:

Circuits in `contracts/circuits`. Unlike tornado-core uses mimcsponge for both commitment and merkle tree. 
Fixed merkle tree class has it's own implementation in utils.
Within utils also functions to create commitments and collect events to rebuild the merkle tree locally.
Script in `scripts/compile-circuits.ts` uses `zokrates-js` to compile on the circuits, generate the verifier contract and a fixture proof for the tests.
MerkleTreeWithHistory.sol heavily inspired from tornado-core, pending to make it more generic for other use cases.
