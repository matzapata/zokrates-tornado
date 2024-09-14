import SHA256 from 'crypto-js/sha256'
import { MerkleTree } from 'merkletreejs'
import CryptoJS from "crypto-js";
import { writeFileSync } from 'fs';
import crypto from 'crypto';


// Helper function to generate a random u32 (32-bit unsigned integer)
function getRandomU32() {
    return Math.floor(Math.random() * 0xFFFFFFFF);  // Generates a random 32-bit unsigned integer
}

// Helper function to convert hex to an array of u32 (ZoKrates format)
const hexToU32Array = (hex: string) => {
    let hexArr: number[] = [];
    for (let i = 0; i < hex.length; i += 8) {
        hexArr.push(parseInt(hex.slice(i, i + 8), 16));
    }
    return hexArr;
};

// Generate random u32 values for secret and nullifier
const secret = hexToU32Array(SHA256('a').toString());
const nullifier = hexToU32Array(SHA256('b').toString());

// Hash the concatenated secret and nullifier arrays
const commitment = crypto.createHash("sha256").update(Buffer.from(secret.concat(nullifier))).toString();

// Hash nullifier with padding (8 zeros)
const padding = CryptoJS.enc.Hex.parse('00000000000000000000000000000000'); // 32 bytes of zeros
const hashed_nullifier = crypto.createHash("sha256").update(Buffer.from(nullifier)).digest("hex");

// Example leaves (these will be hashed)
const leaves = ['b', 'c', 'd'].map(x => SHA256(x).toString())
    .concat(commitment);

// Create the Merkle Tree with SHA256 hashing
const tree = new MerkleTree(leaves, SHA256);
const root = tree.getRoot().toString('hex');
const proof = tree.getProof(commitment);

// Print the inputs for ZoKrates
// console.log("Secret (u32[8]):", secret);
// console.log("Nullifier (u32[8]):", nullifier);
// console.log('Commitment (SHA-256):', commitment);
// console.log('Hashed Nullifier (SHA-256):', hexToU32Array(hashed_nullifier));
// console.log('Root (u32[8]):', hexToU32Array(root));
// console.log('Leaf (u32[8]):', hexToU32Array(commitment));
// console.log('Direction Selector (bool[DEPTH]):', proof.map(p => p.position === 'right'));
// console.log('Path (u32[DEPTH][8]):', proof.map(p => p.data.toString('hex')).map(hex => hexToU32Array(hex)));

const params = [
    hexToU32Array(root).map(r => String(r)),
    hexToU32Array(hashed_nullifier).map(c => String(c)),
    secret.map(s => String(s)),
    nullifier.map(n => String(n)),
    proof.map(p => p.position === 'right'),
    proof.map(p => p.data.toString('hex')).map(hex => hexToU32Array(hex).map(v => String(v)))
]

console.log("root", root)
console.log("hashed_nullifier", hashed_nullifier)

writeFileSync('../contracts/inputs.json', JSON.stringify(params));
