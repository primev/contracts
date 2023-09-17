// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProviderRegistry {
    // Minimum stake required for registration
    uint256 public minStake;

    // Address of the oracle
    address public oracle;

    address public owner;

    address public preConfirmationsContract;

    bool preConfirmationsContractSet; 

    // Mapping from provider addresses to their staked amount
    mapping(address => uint256) public providerStakes;

    // Event for registration
    event ProviderRegistered(address indexed provider, uint256 stakedAmount);

    // Event for depositing funds
    event FundsDeposited(address indexed provider, uint256 amount);

    // Event for slashing funds
    event FundsSlashed(address indexed provider, uint256 amount);

    // Event for rewarding funds
    event FundsRewarded(address indexed provider, uint256 amount);

    constructor(uint256 _minStake, address _oracle) {
        minStake = _minStake;
        oracle = _oracle;
        preConfirmationsContract = address(0);
        owner = msg.sender;
        preConfirmationsContractSet = false;
    }

    modifier onlyPreConfirmationEngine() {
        require(msg.sender == preConfirmationsContract, "Only the pre-confirmations contract can call this funciton");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "Only the oracle can call this function");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function setPreconfirmationsContract(address contractAddress) public onlyOwner {
        require(preConfirmationsContractSet == false, "Preconfirmations Contract is already set and cannot be changed.");
        preConfirmationsContract = contractAddress;
    }

    // Register and stake function
    function RegisterAndStake() external payable {
        require(providerStakes[msg.sender] == 0, "Provider already registered");
        require(msg.value >= minStake, "Insufficient stake");

        providerStakes[msg.sender] = msg.value;
        emit ProviderRegistered(msg.sender, msg.value);
    }

    // Check stake function
    function checkStake(address provider) external view returns (uint256) {
        return providerStakes[provider];
    }

    // Deposit more funds
    function depositFunds() external payable {
        require(providerStakes[msg.sender] > 0, "Provider not registered");
        providerStakes[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    // Slash funds
    function slash(uint256 amt, address provider) external onlyOracle {
        require(providerStakes[provider] >= amt, "Insufficient funds to slash");
        providerStakes[provider] -= amt;
        payable(oracle).transfer(amt);
        emit FundsSlashed(provider, amt);
    }

    // Reward funds
    function reward(uint256 amt, address provider) external onlyOracle {
        require(address(this).balance >= amt, "Insufficient contract balance");
        providerStakes[provider] += amt;
        emit FundsRewarded(provider, amt);
    }
}
