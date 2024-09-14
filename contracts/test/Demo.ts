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

    expect(await demo.doSomethingIfValid(
      proof, 
      "0xd66d35c6c4a5d0fb122c783079f761e4cc6af7a1e7b25a52fb97f1dc4612bca9",
      "0x0f1a97e112798f9bf98288ae89c288df2eb867c3de6fafa15fec625604e94762"
    )).to.be.true;
  })
});
