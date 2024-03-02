// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;
import "forge-std/Script.sol";
import "contracts/BidderRegistry.sol";
import "contracts/ProviderRegistry.sol";
import "contracts/PreConfirmations.sol";
import "contracts/Oracle.sol";
import "contracts/Whitelist.sol";

// Deploy scripts should inherit this contract if they deploy using create2 deterministic addrs.
contract Create2Deployer {
    address constant create2Proxy = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    address constant expectedDeployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function checkCreate2Deployed() internal view {
        require(isContractDeployed(create2Proxy), "Create2 proxy needs to be deployed. See https://github.com/primevprotocol/deterministic-deployment-proxy");
    }

    function checkDeployer() internal view {
        if (msg.sender != expectedDeployer) {
            
        }
    }

    function isContractDeployed(address addr) public view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// Deploys core contracts
contract DeployScript is Script, Create2Deployer {
    function run() external {
        vm.startBroadcast();

        checkCreate2Deployed();
        checkDeployer();

        // Replace these with your contract's constructor parameters
        uint256 minStake = 1 ether;
        address feeRecipient = address(0x68bC10674b265f266b4b1F079Fa06eF4045c3ab9);
        uint16 feePercent = 2;
        uint256 nextRequestedBlockNumber = 4958905;

        // Forge deploy with salt uses create2 proxy from https://github.com/primevprotocol/deterministic-deployment-proxy
        bytes32 salt = 0x8989000000000000000000000000000000000000000000000000000000000000;

        BidderRegistry bidderRegistry = new BidderRegistry{salt: salt}(minStake, feeRecipient, feePercent, msg.sender);
        

        ProviderRegistry providerRegistry = new ProviderRegistry{salt: salt}(minStake, feeRecipient, feePercent, msg.sender);
        

        PreConfCommitmentStore preConfCommitmentStore = new PreConfCommitmentStore{salt: salt}(address(providerRegistry), address(bidderRegistry), feeRecipient, msg.sender);
        

        providerRegistry.setPreconfirmationsContract(address(preConfCommitmentStore));
        

        bidderRegistry.setPreconfirmationsContract(address(preConfCommitmentStore));
        

        Oracle oracle = new Oracle{salt: salt}(address(preConfCommitmentStore), nextRequestedBlockNumber, msg.sender);
        

        preConfCommitmentStore.updateOracle(address(oracle));
        

        vm.stopBroadcast();
    }
}

// Deploys whitelist contract and adds HypERC20 to whitelist
contract DeployWhitelist is Script, Create2Deployer {
    function run() external {

        

        address expectedWhiteListAddr = 0x57508f0B0f3426758F1f3D63ad4935a7c9383620;
        if (isContractDeployed(expectedWhiteListAddr)) {
            
            return;
        }

        vm.startBroadcast();

        checkCreate2Deployed();
        checkDeployer();

        address hypERC20Addr = vm.envAddress("HYP_ERC20_ADDR");
        require(hypERC20Addr != address(0), "Address to whitelist not provided");

        // Forge deploy with salt uses create2 proxy from https://github.com/primevprotocol/deterministic-deployment-proxy
        bytes32 salt = 0x8989000000000000000000000000000000000000000000000000000000000000;

        Whitelist whitelist = new Whitelist{salt: salt}(msg.sender);
        

        whitelist.addToWhitelist(address(hypERC20Addr));
        

        vm.stopBroadcast();
    }
}
