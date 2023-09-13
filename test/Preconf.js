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

      const commitmentSigner = "0x1b6D2283589d0c598202402011A73a6057837687"
      const commitmentHash = "0x31dca6c6fd15593559dabb9e25285f727fd33f07e17ec2e8da266706020034dc"
      const commitmentSignature = "0x80d12ea3cad0cbdcb99a154a8aa8d02ae1c319fca531b5af6cc57bb4a75e6d9e1c001bca320ac1da39945f1fd6389b03c6619c531ceaf2823361b4c8e35b91b301"

      
      const bidHash = await preconf.getBidHash("0xkartik", 2, 2);
      expect(bidHash).to.equal(bHash);
      
      const address = (await preconf.recoverAddress(bidHash, signature));
      expect(address).to.equal(signerAddress);
      
      const txn = await preconf.storeBid(txnHash, 2, 2, signature);
      await txn.wait();

      const bids = await preconf.getBidsFor(address);
      expect(bids[0][3]).to.equal(bHash);

      const contractCommitmentHash = await preconf.getPreConfHash(txnHash, 2, 2, bHash.slice(2), signature.slice(2));
      expect(contractCommitmentHash).to.equal(commitmentHash);

      const commiterAddress = await preconf.recoverAddress(contractCommitmentHash, commitmentSignature);
      expect(commiterAddress).to.equal(commitmentSigner);
    });
  });
});
