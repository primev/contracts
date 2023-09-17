const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
// const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const {ethers} = require("hardhat");


describe("Preconf", function () {

  describe("Deployment", function () {
    it("Should deploy the smart contract and confirm preconf signature validity & bid validity & ensure both user and provider that are part of the preconf have staked eth", async function () {
      // We don't use the fixture here because we want a different deployment
      const [owner, addr1, oracle] = await ethers.getSigners();
      const bidderWallet = new ethers.Wallet("7cea3c338ce48647725ca014a52a80b2a8eb71d184168c343150a98100439d1b", ethers.provider);
      const bidderAddress = bidderWallet.address;

      const commiterWallet = new ethers.Wallet("3bd943ec681f4c2b472aefe2201f88f1ed79592d1202444560e89ad72b2c2665", ethers.provider);

      
      await addr1.sendTransaction({to: bidderAddress, value: ethers.parseEther("20.0")});
      await addr1.sendTransaction({to: commiterWallet.address, value: ethers.parseEther("20.0")});

      const providerRegistry = await ethers.deployContract("ProviderRegistry", [ethers.parseEther("2.0"), addr1]);
      await providerRegistry.waitForDeployment();


      const userRegistry = await ethers.deployContract("UserRegistry", [ethers.parseEther("2.0"), oracle]);
      await userRegistry.waitForDeployment();      

      const txnReciept = await userRegistry.connect(bidderWallet).RegisterAndStake({value: ethers.parseEther("2.0")});
      await txnReciept.wait();

      const commitRegTxn = await providerRegistry.connect(commiterWallet).RegisterAndStake({value: ethers.parseEther("5.0")});
      await commitRegTxn.wait();

      const preconf = await ethers.deployContract("PreConfCommitmentStore", [providerRegistry.target, userRegistry.target]);
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
      
      const txn = await preconf.verifyBid(txnHash, 2, 2, signature);
      console.log("output: ", txn)
      // const bids = await preconf.getBidsFor(address);
      // expect(bids[0][3]).to.equal(bHash);
      // return
      const contractCommitmentHash = await preconf.getPreConfHash(txnHash, 2, 2, bHash, signature.slice(2));
      expect(contractCommitmentHash).to.equal(commitmentHash);

      const commiterAddress = await preconf.recoverAddress(contractCommitmentHash, commitmentSignature);
      expect(commiterAddress).to.equal(commitmentSigner);

      const txnStoreCommitment = await preconf.storeCommitment(txnHash, 2, 2, bHash.slice(2), signature, commitmentHash.slice(2), commitmentSignature);
      await txnStoreCommitment.wait();

      
    });
  });

  it("should allow a provider to sign up to the provider registry", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const providerRegistry = await ethers.deployContract("ProviderRegistry", [ethers.parseEther("2.0"), addr1]);
    await providerRegistry.waitForDeployment();

    console.log("provider address: ", providerRegistry.target)


    const txn = await providerRegistry.connect(addr1).RegisterAndStake({value: ethers.parseEther("2.0")})
    await txn.wait();

    const firstAddrStake = await providerRegistry.checkStake(addr1.address);
    expect(ethers.formatEther(firstAddrStake)).to.equal("2.0");
  });

  it("should allow a user to sign up to the user registry", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const providerRegistry = await ethers.deployContract("UserRegistry", [ethers.parseEther("2.0"), addr1]);
    await providerRegistry.waitForDeployment();

    console.log("provider address: ", providerRegistry.target)


    const txn = await providerRegistry.connect(addr1).RegisterAndStake({value: ethers.parseEther("2.0")})
    await txn.wait();

    const firstAddrStake = await providerRegistry.checkStake(addr1.address);
    expect(ethers.formatEther(firstAddrStake)).to.equal("2.0");
  
  });
});
