# Solidity API

## IUserRegistry

### PreConfCommitment

```solidity
struct PreConfCommitment {
  string txnHash;
  uint64 bid;
  uint64 blockNumber;
  string bidHash;
  string bidSignature;
  string commitmentHash;
  string commitmentSignature;
}
```

### registerAndStake

```solidity
function registerAndStake() external payable
```

### checkStake

```solidity
function checkStake(address user) external view returns (uint256)
```

### retrieveFunds

```solidity
function retrieveFunds(address user, uint256 amt, address payable provider) external
```

