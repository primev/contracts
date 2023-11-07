// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const ethers = require("ethers");
const hre = require("hardhat");

async function main() {
  const minStake = "1000000000000000000";
  const feeRecipient = "0x388C818CA8B9251b393131C08a736A67ccB19297";
  const oracle = "0x388C818CA8B9251b393131C08a736A67ccB19297";
  const feePercent = "15";

  let signer;

  if (process.env.PRIVATE_KEY) {
    const wallet = new hre.ethers.Wallet(process.env.PRIVATE_KEY, hre.ethers.provider);
    signer = wallet;
  } else {
    // Use default Hardhat signer if PRIVATE_KEY not set
    [signer] = await hre.ethers.getSigners();
  }

  const UserRegistry = await hre.ethers.deployContract("UserRegistry", [
    minStake,
    feeRecipient,
    feePercent,
  ], { signer });
  await UserRegistry.waitForDeployment();
  console.log("UserRegistry deployed to:", UserRegistry.target);

  const ProviderRegistry = await hre.ethers.deployContract("ProviderRegistry", [
    minStake,
    feeRecipient,
    feePercent,
  ], { signer });
  await ProviderRegistry.waitForDeployment();
  console.log("ProviderRegistry deployed to:", ProviderRegistry.target);

  const PreConfCommitmentStore = await hre.ethers.deployContract(
    "PreConfCommitmentStore",
    [UserRegistry.target, ProviderRegistry.target, oracle]
  , { signer });
  await PreConfCommitmentStore.waitForDeployment();
  console.log(
    "PreConfCommitmentStore deployed to:",
    PreConfCommitmentStore.target
  , { signer });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
