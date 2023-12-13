// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Script.sol";
import "contracts/UserRegistry.sol";
import "contracts/ProviderRegistry.sol";
import "contracts/PreConfirmations.sol";
import "contracts/Oracle.sol";
import "contracts/Whitelist.sol";

// Deploys core contracts
contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Replace these with your contract's constructor parameters
        uint256 minStake = 1 ether;
        address feeRecipient = address(0x68bC10674b265f266b4b1F079Fa06eF4045c3ab9);
        uint16 feePercent = 2;
        uint256 nextRequestedBlockNumber = 18682511;

        UserRegistry userRegistry = new UserRegistry(minStake, feeRecipient, feePercent);
        console.log("UserRegistry deployed to:", address(userRegistry));

        ProviderRegistry providerRegistry = new ProviderRegistry(minStake, feeRecipient, feePercent);
        console.log("ProviderRegistry deployed to:", address(providerRegistry));

        PreConfCommitmentStore preConfCommitmentStore = new PreConfCommitmentStore(address(providerRegistry), address(userRegistry), feeRecipient);
        console.log("PreConfCommitmentStore deployed to:", address(preConfCommitmentStore));

        providerRegistry.setPreconfirmationsContract(address(preConfCommitmentStore));
        console.log("ProviderRegistry updated with PreConfCommitmentStore address:", address(preConfCommitmentStore));

        userRegistry.setPreconfirmationsContract(address(preConfCommitmentStore));
        console.log("UserRegistry updated with PreConfCommitmentStore address:", address(preConfCommitmentStore));

        Oracle oracle = new Oracle(address(preConfCommitmentStore), nextRequestedBlockNumber);
        console.log("Oracle deployed to:", address(oracle));

        preConfCommitmentStore.updateOracle(address(oracle));
        console.log("PreConfCommitmentStore updated with Oracle address:", address(oracle));

        vm.stopBroadcast();
    }
}

// Deploys whitelist contract and adds HypERC20 to whitelist
contract DeployWhitelist is Script {
    function run() external {
        vm.startBroadcast();

        address create2Proxy = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
        require(isContractDeployed(create2Proxy), "Create2 proxy needs to be deployed. See https://github.com/primevprotocol/deterministic-deployment-proxy");

        address hypERC20Addr = vm.envAddress("HYP_ERC20_ADDR");
        require(hypERC20Addr != address(0), "Whitelist address not provided");

        // Forge deploy with salt uses create2 proxy from https://github.com/primevprotocol/deterministic-deployment-proxy
        bytes32 salt = 0x8989000000000000000000000000000000000000000000000000000000000000;
        address constDeployer = 0xBe3dEF3973584FdcC1326634aF188f0d9772D57D;
        Whitelist whitelist = new Whitelist{salt: salt}(constDeployer);
        console.log("Whitelist deployed to:", address(whitelist));
        console.log("Expected: 0xe57ee51bcb0914EC666703F923e0433d8c4d70b1");

        whitelist.addToWhitelist(address(hypERC20Addr));
        console.log("Whitelist updated with hypERC20 address:", address(hypERC20Addr));

        vm.stopBroadcast();
    }

    function isContractDeployed(address addr) public view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
