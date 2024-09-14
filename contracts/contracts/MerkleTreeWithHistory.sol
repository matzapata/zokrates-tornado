// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHasherAdapter {
    function hash(bytes32 _left, bytes32 _right) external returns (bytes32);
}

contract Keccak256Adapter is IHasherAdapter {
    function hash(
        bytes32 left,
        bytes32 right
    ) external pure override returns (bytes32) {
        return keccak256(abi.encodePacked(left, right));
    }
}

interface IMiMCHasher {
    function MiMCSponge(
        uint256 in_xL,
        uint256 in_xR
    ) external pure returns (uint256 xL, uint256 xR);
}

contract MiMCAdapter is IHasherAdapter {
    IMiMCHasher public immutable hasher;
    uint256 public FIELD_SIZE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617; // BASED ON HASH function

    constructor(IMiMCHasher _hasher) {
        hasher = _hasher;
    }

    function hash(bytes32 left, bytes32 right) external view returns (bytes32) {
        uint256 R = uint256(left);
        uint256 C = 0;
        (R, C) = hasher.MiMCSponge(R, C);
        R = addmod(R, uint256(right), FIELD_SIZE);
        (R, C) = hasher.MiMCSponge(R, C);
        return bytes32(R);
    }
}

contract MerkleTreeWithHistory {
    uint256 public ZERO_VALUE =
        21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE
    IHasherAdapter public immutable hasher;

    uint32 public levels;

    // the following variables are made public for easier testing and debugging and
    // are not supposed to be accessed in regular code

    // filledSubtrees and roots could be bytes32[size], but using mappings makes it cheaper because
    // it removes index range check on every interaction
    mapping(uint256 => bytes32) public filledSubtrees;
    mapping(uint256 => bytes32) public roots;
    uint32 public constant ROOT_HISTORY_SIZE = 30;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;

    constructor(uint32 _levels, IHasherAdapter _hasher) {
        require(_levels > 0, "_levels should be greater than zero");
        require(_levels < 32, "_levels should be less than 32");
        levels = _levels;
        hasher = _hasher;

        for (uint32 i = 0; i < _levels; i++) {
            filledSubtrees[i] = zeros(i);
        }

        roots[0] = zeros(_levels - 1);
    }

    function _insert(bytes32 _leaf) internal returns (uint32 index) {
        uint32 _nextIndex = nextIndex;
        require(
            _nextIndex != uint32(2) ** levels,
            "Merkle tree is full. No more leaves can be added"
        );
        uint32 currentIndex = _nextIndex;
        bytes32 currentLevelHash = _leaf;
        bytes32 left;
        bytes32 right;

        for (uint32 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeros(i);
                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }
            currentLevelHash = hasher.hash(left, right);
            currentIndex /= 2;
        }

        uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        currentRootIndex = newRootIndex;
        roots[newRootIndex] = currentLevelHash;
        nextIndex = _nextIndex + 1;
        return _nextIndex;
    }

    ///  @dev Whether the root is present in the root history
    function isKnownRoot(bytes32 _root) public view returns (bool) {
        if (_root == 0) {
            return false;
        }
        uint32 _currentRootIndex = currentRootIndex;
        uint32 i = _currentRootIndex;
        do {
            if (_root == roots[i]) {
                return true;
            }
            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            i--;
        } while (i != _currentRootIndex);
        return false;
    }

    ///  @dev Returns the last root
    function getLastRoot() public view returns (bytes32) {
        return roots[currentRootIndex];
    }

    /// @dev provides Zero (Empty) elements. A more efficent implementation would be precomputed
    function zeros(uint256 i) public returns (bytes32) {
        if (i == 0) {
            return bytes32(ZERO_VALUE);
        } else {
            return hasher.hash(zeros(i - 1), zeros(i - 1));
        }
    }
}
