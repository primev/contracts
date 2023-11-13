// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "forge-std/Script.sol";
import "contracts/UserRegistry.sol";
import "contracts/ProviderRegistry.sol";
import "contracts/PreConfirmations.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Replace these with your contract's constructor parameters
        uint256 minStake = 1 ether;
        address feeRecipient = address(0x388C818CA8B9251b393131C08a736A67ccB19297);
        uint16 feePercent = 15;

        UserRegistry userRegistry = new UserRegistry(minStake, feeRecipient, feePercent);
        console.log("UserRegistry deployed to:", address(userRegistry));

        ProviderRegistry providerRegistry = new ProviderRegistry(minStake, feeRecipient, feePercent);
        console.log("ProviderRegistry deployed to:", address(providerRegistry));

        PreConfCommitmentStore preConfCommitmentStore = new PreConfCommitmentStore(address(userRegistry), address(providerRegistry), feeRecipient);
        console.log("PreConfCommitmentStore deployed to:", address(preConfCommitmentStore));

        vm.stopBroadcast();
    }
}
