// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ValidatorRegistry is Ownable {

    address public slashRecipient;
    uint256 public minStake;

    mapping(address => uint256) public stakedBalances;
    mapping(address => address) public stakeOriginators;

    event SelfStake(address indexed staker, uint256 amount);
    event StakeSplit(address indexed staker, address[] recipients, uint256 totalAmount);
    event StakeWithdrawn(address indexed staker, uint256 amount);

    constructor(
        uint256 _minStake,
        address _slashRecipient
    ) {
        require(_minStake > 0, "Minimum stake must be greater than 0");
        require(_slashRecipient != address(0), "Slash recipient must be a valid address");

        minStake = _minStake;
        slashRecipient = _slashRecipient;
    }

    function selfStake() external payable {
        require(msg.value >= minStake, "Stake amount must meet the minimum requirement");
        require(stakedBalances[msg.sender] == 0, "Already staked");

        stakedBalances[msg.sender] += msg.value;
        stakeOriginators[msg.sender] = msg.sender;

        emit SelfStake(msg.sender, msg.value);
    }

    function splitStake(address[] calldata recipients) external payable {
        require(recipients.length > 0, "There must be at least one recipient");

        uint256 splitAmount = msg.value / recipients.length;
        require(splitAmount >= minStake, "Split amount must meet the minimum requirement");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(stakedBalances[recipients[i]] == 0, "Recipient already staked");
            stakedBalances[recipients[i]] += splitAmount;
            stakeOriginators[recipients[i]] = msg.sender;
        }

        emit StakeSplit(msg.sender, recipients, msg.value);
    }

    function withdraw(address[] calldata fromAddrs) external {
        for (uint256 i = 0; i < fromAddrs.length; i++) {
            require(stakedBalances[fromAddrs[i]] > 0, "No staked balance to withdraw");
            require(stakeOriginators[fromAddrs[i]] == msg.sender || fromAddrs[i] == msg.sender, "Not authorized to withdraw. Must be stake originator or EOA who's staked");

            uint256 amount = stakedBalances[fromAddrs[i]];
            stakedBalances[fromAddrs[i]] -= amount;
            (bool sent, ) = msg.sender.call{value: amount}("");
            require(sent, "Failed to withdraw stake");
            stakeOriginators[fromAddrs[i]] = address(0);

            emit StakeWithdrawn(msg.sender, amount);
        }
    }

    function isStaked(address staker) external view returns (bool) {
        return stakedBalances[staker] >= minStake;
    }
}
