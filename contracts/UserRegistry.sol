// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title User Registry
/// @author Kartik Chopra
/// @notice This contract is for user registry and staking.
contract UserRegistry is Ownable, ReentrancyGuard {
    /// @dev Minimum stake required for registration
    uint256 public minStake;

    /// @dev Address of the pre-confirmations contract
    address public preConfirmationsContract;

    /// @dev Mapping for if user is registered
    mapping(address => bool) public userRegistered;

    /// @dev Mapping from user addresses to their staked amount
    mapping(address => uint256) public userStakes;

    /// @dev Event emitted when a user is registered with their staked amount
    event UserRegistered(address indexed user, uint256 stakedAmount);

    /// @dev Event emitted when funds are retrieved from a user's stake
    event FundsRetrieved(address indexed user, uint256 amount);

    struct PreConfCommitment {
        string txnHash;
        uint64 bid;
        uint64 blockNumber;
        string bidHash;
        string bidSignature;
        string commitmentHash;
        string commitmentSignature;
    }

    /**
     * @dev Fallback function to revert all calls, ensuring no unintended interactions.
     */
    fallback() external payable {
        revert("Invalid call");
    }

    /**
     * @dev Receive function registers users and takes their stake
     * Should be removed from here in case the registerAndStake function becomes more complex
     */
    receive() external payable {
        registerAndStake();
    }

    /**
     * @dev Constructor to initialize the contract with a minimum stake requirement.
     * @param _minStake The minimum stake required for user registration.
     */
    constructor(uint256 _minStake) Ownable(msg.sender) {
        minStake = _minStake;
    }

    /**
     * @dev Modifier to restrict a function to only be callable by the pre-confirmations contract.
     */
    modifier onlyPreConfirmationEngine() {
        require(
            msg.sender == preConfirmationsContract,
            "Only the pre-confirmations contract can call this function"
        );
        _;
    }

    /**
     * @dev Sets the pre-confirmations contract address. Can only be called by the owner.
     * @param contractAddress The address of the pre-confirmations contract.
     */
    function setPreconfirmationsContract(
        address contractAddress
    ) public onlyOwner {
        require(
            preConfirmationsContract == address(0),
            "Preconfirmations Contract is already set and cannot be changed."
        );
        preConfirmationsContract = contractAddress;
    }

    /**
     * @dev Internal function for user registration and staking.
     */
    function registerAndStake() public payable {
        require(!userRegistered[msg.sender], "User already registered");
        require(msg.value >= minStake, "Insufficient stake");

        userStakes[msg.sender] = msg.value;
        userRegistered[msg.sender] = true;

        emit UserRegistered(msg.sender, msg.value);
    }

    /**
     * @dev Check the stake of a user.
     * @param user The address of the user.
     * @return The staked amount for the user.
     */
    function checkStake(address user) external view returns (uint256) {
        return userStakes[user];
    }

    /**
     * @dev Retrieve funds from a user's stake (only callable by the pre-confirmations contract).
     * @dev reenterancy not necessary but still putting here for precaution
     * @param user The address of the user.
     * @param amt The amount to retrieve from the user's stake.
     * @param provider The address to transfer the retrieved funds to.
     */
    function retrieveFunds(
        address user,
        uint256 amt,
        address payable provider
    ) external nonReentrant onlyPreConfirmationEngine {
        uint256 amount = userStakes[user];
        require(
            amount >= amt,
            "Amount to retrieve bigger than available funds"
        );
        userStakes[user] -= amt;

        (bool success, ) = provider.call{value: amt}("");
        require(success, "couldn't transfer to user");

        emit FundsRetrieved(user, amount);
    }
}
