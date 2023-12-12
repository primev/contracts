// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;
import "forge-std/Script.sol";
import "contracts/UserRegistry.sol";
import "contracts/ProviderRegistry.sol";
import "contracts/PreConfirmations.sol";
import "contracts/Oracle.sol";

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
