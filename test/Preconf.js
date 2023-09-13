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
      const bHash = "0x86ac45fb1e987a6c8115494cd4fd82f6756d359022cdf5ea19fd2fac1df6e7f0"
      const signature = "0x33683da4605067c9491d665864b2e4e7ade8bc57921da9f192a1b8246a941eaa2fb90f72031a2bf6008fa590158591bb5218c9aace78ad8cf4d1f2f4d74bc3e901"
      const signerAddress = "0x3533d88fC84531a6542C8c09b27e7D292f6537B5"
      
      const bidHash = await preconf.getBidHash("0xkartik", 2, 2);
      expect(bidHash).to.equal(bHash);
      
      const address = (await preconf.recoverAddress(txnHash, 2, 2, signature))[0];
      expect(address).to.equal(signerAddress);
      
      const txn = await preconf.storeBid(txnHash, 2, 2, signature);
      await txn.wait();

      const bids = await preconf.getBidsFor(address);
      expect(bids[0][3]).to.equal(bHash);
    });
  });
});
