pragma solidity ^0.8.0;

import "./IBuilderRegistry.sol";

contract BuilderRegistry is IBuilderRegistry {
    struct Builder {
        address builderAddress;
        uint256 stakedAmount;
        bool isRegistered;
    }

    mapping(address => Builder) public builders;
    uint256 public minStakeAmount;

    constructor() {
        minStakeAmount = 10 ether;
    }

    function registerAndStake() public payable {
        require(msg.value >= minStakeAmount, "Insufficient stake amount");

        if (!builders[msg.sender].isRegistered) {
            builders[msg.sender] = Builder({
                builderAddress: msg.sender,
                stakedAmount: msg.value,
                isRegistered: true
            });
        } else {
            builders[msg.sender].stakedAmount += msg.value;
        }
    }

    function slashBuilder(address builderAddress) public {
        // Implement fraud proof validation logic here
        // ...

        Builder storage builder = builders[builderAddress];
        require(builder.isRegistered, "Builder not registered");

        uint256 slashAmount = builder.stakedAmount;
        builder.stakedAmount = 0;

        // Transfer slashed amount to the caller
        (bool success, ) = msg.sender.call{value: slashAmount}("");
        require(success, "Transfer failed");
    }
    
    function isBuilderRegistered(address builderAddress) external view override returns (bool) {
        return builders[builderAddress].isRegistered;
    }
}