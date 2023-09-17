// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserRegistry {
    // Minimum stake required for registration
    uint256 public minStake;

    // Address of the oracle
    address public oracle;

    // Mapping from user addresses to their staked amount
    mapping(address => uint256) public userStakes;

    // Mapping to keep track of used PreConfCommitments
    mapping(bytes32 => bool) public usedCommitments;

    // Event for registration
    event UserRegistered(address indexed user, uint256 stakedAmount);

    // Event for retrieving funds
    event FundsRetrieved(address indexed user, uint256 amount, string txnHash);

    struct PreConfCommitment {
        string txnHash;
        uint64 bid;
        uint64 blockNumber;
        string bidHash;
        string bidSignature;

        string commitmentHash;
        string commitmentSignature;
    }

    constructor(uint256 _minStake, address _oracle) {
        minStake = _minStake;
        oracle = _oracle;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "Only the oracle can call this function");
        _;
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
    function RetrieveFunds(address user, PreConfCommitment memory preConf) external onlyOracle {
        uint256 amount = userStakes[user];
        require(amount > 0, "No funds available for retrieval");

        // Calculate the hash of the PreConfCommitment to check for replays
        bytes32 commitmentHash = keccak256(abi.encode(preConf));
        require(!usedCommitments[commitmentHash], "Commitment already used");

        // Mark this commitment as used to prevent replays
        usedCommitments[commitmentHash] = true;

        // Logic for validating PreConfCommitment (omitted for simplicity)
        // ...

        // Transfer funds to Oracle
        payable(oracle).transfer(amount);
        userStakes[user] = 0;

        emit FundsRetrieved(user, amount, preConf.txnHash);
    }
}
