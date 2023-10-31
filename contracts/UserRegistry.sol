// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title User Registry
/// @author Kartik Chopra
/// @notice This contract is for user registry and staking.
contract UserRegistry is Ownable, ReentrancyGuard {
    /// @dev For improved precision
    uint256 constant PRECISION = 10 ** 25;
    uint256 constant PERCENT = 100 * PRECISION;

    /// @dev Fee percent that would be taken by protocol when provider is slashed
    uint16 public feePercent;

    /// @dev Minimum stake required for registration
    uint256 public minStake;

    /// @dev Amount assigned to feeRecipient
    uint256 public feeRecipientAmount;

    /// @dev protocol fee, left over amount when there is no fee recipient assigned
    uint256 public protocolFeeAmount;

    /// @dev Address of the pre-confirmations contract
    address public preConfirmationsContract;

    /// @dev Fee recipient
    address public feeRecipient;

    /// @dev Mapping for if user is registered
    mapping(address => bool) public userRegistered;

    /// @dev Mapping from user addresses to their staked amount
    mapping(address => uint256) public userStakes;

    /// @dev Amount assigned to users
    mapping(address => uint256) public providerAmount;

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
     * @param _feeRecipient The address that receives fee
     * @param _feePercent The fee percentage for protocol
     */
    constructor(
        uint256 _minStake,
        address _feeRecipient,
        uint16 _feePercent
    ) Ownable(msg.sender) {
        minStake = _minStake;
        feeRecipient = _feeRecipient;
        feePercent = _feePercent;
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
    ) external onlyOwner {
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

        uint256 feeAmt = (amt * uint256(feePercent) * PRECISION) / PERCENT;
        uint256 amtMinusFee = amt - feeAmt;

        if (feeRecipient != address(0)) {
            feeRecipientAmount += feeAmt;
        } else {
            protocolFeeAmount += feeAmt;
        }

        providerAmount[provider] += amtMinusFee;

        emit FundsRetrieved(user, amount);
    }

    /**
     * @notice Sets the new fee recipient
     * @dev onlyOwner restriction
     * @param newFeeRecipient The address to transfer the slashed funds to.
     */
    function setNewFeeRecipient(address newFeeRecipient) external onlyOwner {
        feeRecipient = newFeeRecipient;
    }

    /**
     * @notice Sets the new fee recipient
     * @dev onlyOwner restriction
     * @param newFeePercent this is the new fee percent
     */
    function setNewFeePercent(uint16 newFeePercent) external onlyOwner {
        feePercent = newFeePercent;
    }

    function withdrawFeeRecipientAmount() external nonReentrant {
        uint256 amount = feeRecipientAmount;
        feeRecipientAmount = 0;
        (bool successFee, ) = feeRecipient.call{value: amount}("");
        require(successFee, "Couldn't transfer to fee Recipient");
    }

    function withdrawProviderAmount(address provider) external nonReentrant {
        uint256 amount = providerAmount[provider];
        providerAmount[provider] = 0;

        require(amount > 0, "provider Amount is zero");

        (bool success, ) = provider.call{value: amount}("");
        require(success, "Couldn't transfer to provider");
    }

    function withdrawStakedAmount(address user) external nonReentrant {
        uint256 stake = userStakes[user];
        userStakes[user] = 0;
        require(msg.sender == user, "Only user can unstake");
        require(stake > 0, "Provider Staked Amount is zero");

        (bool success, ) = user.call{value: stake}("");
        require(success, "Couldn't transfer stake to user");
    }

    function withdrawProtocolFee(
        address user,
        uint256 amount
    ) external onlyOwner nonReentrant {
        uint256 _protocolFeeAmount = protocolFeeAmount;
        require(
            _protocolFeeAmount >= amount,
            "In sufficient protocol fee amount"
        );
        protocolFeeAmount = protocolFeeAmount - amount;

        (bool success, ) = user.call{value: amount}("");
        require(success, "Couldn't transfer stake to user");
    }
}
