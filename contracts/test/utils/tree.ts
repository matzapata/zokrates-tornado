// based on https://github.com/tornadocash/fixed-merkle-tree

import * as crypto from 'crypto'
import { buildMimcSponge } from 'circomlibjs'
import { ethers } from 'hardhat'

const ZERO_VALUE = BigInt('21663839004416932945382355908790599225266501822907911457504978515578255421292') // = keccak256("tornado") % FIELD_SIZE

export class FixedMerkleTree {
    private elements: bigint[] = []
    private layers: bigint[][] = []
    private zeros: bigint[] = []
    private capacity = 0
    private levels = 0
    private hashFn: (l: bigint, right: bigint) => bigint
    public root: bigint;

    constructor(levels: number, elements?: bigint[], hashFn?: (l: any, right: any) => any) {
        this.levels = levels
        this.capacity = 2 ** this.levels
        this.hashFn = hashFn ?? ((l, r) => l + r)

        this.zeros[0] = ZERO_VALUE
        for (let i = 1; i <= levels; i++) {
            this.zeros[i] = this.hashFn(this.zeros[i - 1], this.zeros[i - 1]);
        }

        this.elements = elements ?? [];

        const { root, layers } = this.computeTree(this.elements)

        this.layers = layers
        this.root = root
    }

    insert(element: bigint) {
        if (this.elements.length > this.capacity) {
            throw new Error('Tree is full')
        }

        this.elements.push(element)

        const { root, layers } = this.computeTree(this.elements)

        this.layers = layers
        this.root = root
    }

    path(element: bigint) {
        let pathElements = []
        let pathIndices = []

        // calculate path
        let index = this.layers[0].findIndex(e => BigInt(e) == BigInt(element))

        for (let level = 0; level < this.levels; level++) {
            pathIndices[level] = index % 2
            pathElements[level] =
                index % 2 === 0
                    ? (index + 1 < this.layers[level].length
                        ? this.layers[level][index + 1]
                        : this.zeros[level]
                    ) : this.layers[level][index - 1]

            index /= 2
        }

        return {
            pathElements: pathElements.map((v) => v.toString()),
            pathIndices: pathIndices.map((v) => v.toString()),
            pathDirection: pathIndices.map((v) => v === 0 ? false : true),
        }
    }

    private computeTree(elements: bigint[]): { root: bigint, layers: bigint[][] } {
        let layers: bigint[][] = []
        layers[0] = elements.slice() // layers[0] = base | layers[level] = root
        for (let level = 1; level <= this.levels; level++) {
            layers[level] = []
            for (let i = 0; i < Math.ceil(layers[level - 1].length / 2); i++) {
                const leftElement = layers[level - 1][i * 2]
                const hasRightSibling = (i * 2 + 1) < layers[level - 1].length;
                const rightElement = hasRightSibling
                    ? layers[level - 1][i * 2 + 1]
                    : this.zeros[level - 1];

                layers[level][i] = this.hashFn(leftElement, rightElement)
            }
        }

        const root = layers[this.levels].length > 0 ? layers[this.levels][0] : this.zeros[this.levels - 1]

        return { root, layers };
    }


}

export function calculateHash(mimc: any, left: any, right: any) {
    return BigInt(mimc.F.toString(mimc.multiHash([left, right])))
}

export async function generateCommitment() {
    const mimc = await buildMimcSponge();
    const nullifier = BigInt("0x" + crypto.randomBytes(31).toString("hex")).toString()
    const secret = BigInt("0x" + crypto.randomBytes(31).toString("hex")).toString()
    const commitment = mimc.F.toString(mimc.multiHash([nullifier, secret]))
    const nullifierHash = mimc.F.toString(mimc.multiHash([nullifier]))

    return {
        nullifier: nullifier,
        secret: secret,
        commitment: commitment,
        nullifierHash: nullifierHash
    }
}

export function generateZeros(mimc: any, levels: number) {
    let zeros = []
    zeros[0] = ZERO_VALUE
    for (let i = 1; i <= levels; i++)
        zeros[i] = calculateHash(mimc, zeros[i - 1], zeros[i - 1]);
    return zeros
}

// calculates Merkle root from elements and a path to the given element 
export function calculateMerkleRootAndPath(mimc: any, levels: number, elements: any[], element?: any) {
    const capacity = 2 ** levels
    if (elements.length > capacity) throw new Error('Tree is full')

    const zeros = generateZeros(mimc, levels);
    let layers = []
    layers[0] = elements.slice() // layers[0] = base | layers[level] = root
    for (let level = 1; level <= levels; level++) {
        layers[level] = []
        for (let i = 0; i < Math.ceil(layers[level - 1].length / 2); i++) {
            const leftElement = layers[level - 1][i * 2]
            const hasRightSibling = (i * 2 + 1) < layers[level - 1].length;
            const rightElement = hasRightSibling
                ? layers[level - 1][i * 2 + 1]
                : zeros[level - 1];

            layers[level][i] = calculateHash(mimc, leftElement, rightElement)
        }
    }

    const root = layers[levels].length > 0 ? layers[levels][0] : zeros[levels - 1]

    let pathElements = []
    let pathIndices = []

    // calculate path
    if (element) {
        let index = layers[0].findIndex(e => BigInt(e) == BigInt(element))

        for (let level = 0; level < levels; level++) {
            pathIndices[level] = index % 2
            pathElements[level] =
                index % 2 === 0
                    ? (index + 1 < layers[level].length
                        ? layers[level][index + 1]
                        : zeros[level]
                    ) : layers[level][index - 1]

            index /= 2
        }
    }

    return {
        root: root.toString(),
        pathElements: pathElements.map((v) => v.toString()),
        pathIndices: pathIndices.map((v) => v.toString()),
        pathDirection: pathIndices.map((v) => v === 0 ? false : true),
    }
}

export function checkMerkleProof(mimc: any, levels: number, pathElements: any[], pathIndices: any[], element: any) {
    // console.log(pathElements)
    // console.log(pathIndices)
    let hashes = []
    for (let i = 0; i < levels; i++) {
        const in0: any = (i == 0) ? element : hashes[i - 1]
        const in1 = pathElements[i]
        // console.log(`in0: ${in0} in1: ${in1}`)
        if (pathIndices[i] == 0) {
            hashes[i] = calculateHash(mimc, in0, in1)
        } else {
            hashes[i] = calculateHash(mimc, in1, in0)
        }
        // console.log(`in0: ${in0} in1: ${in1} hash: ${hashes[i]}`)
    }
    return hashes[levels - 1]
}

export async function calculateMerkleRootAndPathFromEvents(mimc: any, address: any, provider: any, levels: number, element: any) {
    const abi = [
        "event Commit(bytes32 indexed commitment,uint32 leafIndex,uint256 timestamp)"
    ];
    const contract = new ethers.Contract(address, abi, provider)
    const events = await contract.queryFilter(contract.filters.Commit())
    let commitments = []
    for (let event of events) {
        if (!(event as any)?.args.commitment) continue;
        commitments.push(BigInt((event as any)?.args.commitment))
    }
    return calculateMerkleRootAndPath(mimc, levels, commitments, element)
}
