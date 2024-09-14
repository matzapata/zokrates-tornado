import SHA256 from 'crypto-js/sha256'
import { MerkleTree } from 'merkletreejs'
import CryptoJS from "crypto-js";
import { writeFileSync } from 'fs';
import crypto from 'crypto';


// Create the Merkle Tree with SHA256 hashing
const tree = new MerkleTree([].map(v => SHA256(v).toString()), SHA256);

// tree.addLeaf(Buffer.from(SHA256('a').toString(), "utf-8"), false);

const root = tree.getRoot().toString('hex');
console.log("root", root)
