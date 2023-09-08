const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
// const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const {ethers} = require("hardhat");


describe("Preconf", function () {

  describe("Deployment", function () {
    it("Should deploy the smart contract and store info", async function () {
      // We don't use the fixture here because we want a different deployment
      const preconf = await ethers.deployContract("PreConfCommitmentStore");
      await preconf.waitForDeployment();

  
      console.log("Preconf contract deployed locally at: ", preconf.target)

      /*
         string memory txnHash,
        uint64 bid,
        uint64 blockNumber,
        string memory bidHash,
        string memory bidSignature,
        string memory commitmentSignature
      // */
      // const bidTxn = await preconf.storeCommitment("0xkartik", 100, 100, "0xkartik", "0xkartik", "0xkartik");
      // const reciept = await bidTxn.wait();
      console.log( await preconf.getDomainSeperator());
      console.log( await preconf.getMessageTypeHash());
      console.log( await preconf.typedDataHash());  
      const bidHash = await preconf.hashMessage("0xkartik", 2, 2);
      console.log(bidHash);
      // const commitments = await preconf.retreiveCommitments();
      // console.log(commitments);
    });
  });
});
