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
      const txnHash = "0xkartik"
      const bid = 2
      const blockNumber = 2
      const bHash = "86ac45fb1e987a6c8115494cd4fd82f6756d359022cdf5ea19fd2fac1df6e7f0"
      const signature = "0x33683da4605067c9491d665864b2e4e7ade8bc57921da9f192a1b8246a941eaa2fb90f72031a2bf6008fa590158591bb5218c9aace78ad8cf4d1f2f4d74bc3e901"
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
      const address = await preconf.recoverAddress("0xkartik", 2, 2, signature);
      console.log(address);
      // const commitments = await preconf.retreiveCommitments();
      // console.log(commitments);
    });
  });
});
