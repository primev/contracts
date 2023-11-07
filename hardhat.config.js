require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
require("solidity-docgen");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.15",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545", // Ganache default port
    },
    hardhat: {},
    op_docker: {
      url: "http://op-geth:8545", 
    },
  },
  docgen: {
    pages: "files",
    exclude: ["contracts/interfaces", "lib"],
  },
};
