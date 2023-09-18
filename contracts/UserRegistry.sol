// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserRegistry {
    // Minimum stake required for registration
    uint256 public minStake;

    address public owner;

    address public preConfirmationsContract;

    bool preConfirmationsContractSet; 

    // Mapping from user addresses to their staked amount
    mapping(address => uint256) public userStakes;

    // Event for registration
    event UserRegistered(address indexed user, uint256 stakedAmount);

    // TODO(ckartik): Remove any concept of a preconfimration from UserRegistry
    
    // Event for retrieving funds
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

    constructor(uint256 _minStake) {
        minStake = _minStake;
        preConfirmationsContract = address(0);
        owner = msg.sender;
        preConfirmationsContractSet = false;
    }

    modifier onlyPreConfirmationEngine() {
        require(msg.sender == preConfirmationsContract, "Only the pre-confirmations contract can call this funciton");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function setPreconfirmationsContract(address contractAddress) public onlyOwner {
        require(preConfirmationsContractSet == false, "Preconfirmations Contract is already set and cannot be changed.");
        preConfirmationsContract = contractAddress;
        preConfirmationsContractSet = true;
    }

    // Register and stake function
    function RegisterAndStake() external payable {
        require(userStakes[msg.sender] == 0, "User already registered");
        require(msg.value >= minStake, "Insufficient stake");

        userStakes[msg.sender] = msg.value;
        emit UserRegistered(msg.sender, msg.value);
    }

    // Check stake function
    function checkStake(address user) external view returns (uint256) {
        return userStakes[user];
    }
    

    // Retrieve funds (only callable by Oracle)
    function RetrieveFunds(address user, uint256 amt, address payable provider) external onlyPreConfirmationEngine {
        uint256 amount = userStakes[user];
        require(amount >= amt, "No funds available for retrieval");

        provider.transfer(amt);

        userStakes[user] -= amt;

        emit FundsRetrieved(user, amount);
    }
}
