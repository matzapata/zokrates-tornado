import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { loadProof } from "./utils/load-proof";
import { expect } from "chai";
import hre from "hardhat";

describe("Demo", function () {
  async function deployFixture() {
    const Demo = await hre.ethers.getContractFactory("Demo");
    const demo = await Demo.deploy()

    const { proof, inputs } = loadProof()

    return { demo, proof, inputs };
  }

  it("Should verify transaction", async () => {
    const { demo, proof, inputs } = await loadFixture(deployFixture);

    expect(await demo.doSomethingIfValid(proof, inputs)).to.be.true;
  })
});
