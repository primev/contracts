# Solidity API

## IProviderRegistry

### registerAndStake

```solidity
function registerAndStake() external payable
```

### checkStake

```solidity
function checkStake(address provider) external view returns (uint256)
```

### depositFunds

```solidity
function depositFunds() external payable
```

### slash

```solidity
function slash(uint256 amt, address provider, address payable user) external
```

### reward

```solidity
function reward(uint256 amt, address provider) external
```

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

## PreConfCommitmentStore

This contract allows users to make precommitments and bids and provides a mechanism for the oracle to verify and process them.

_This contract should not be used in production as it is for demonstration purposes._

### EIP712_COMMITMENT_TYPEHASH

```solidity
bytes32 EIP712_COMMITMENT_TYPEHASH
```

_EIP-712 Type Hash for preconfirmation commitment_

### EIP712_MESSAGE_TYPEHASH

```solidity
bytes32 EIP712_MESSAGE_TYPEHASH
```

_EIP-712 Type Hash for preconfirmation bid_

### commitmentCount

```solidity
uint256 commitmentCount
```

_commitment counter_

### oracle

```solidity
address oracle
```

_Address of the oracle_

### DOMAIN_SEPARATOR_PRECONF

```solidity
bytes32 DOMAIN_SEPARATOR_PRECONF
```

### DOMAIN_SEPARATOR_BID

```solidity
bytes32 DOMAIN_SEPARATOR_BID
```

### providerRegistry

```solidity
contract IProviderRegistry providerRegistry
```

_Address of provider registry_

### userRegistry

```solidity
contract IUserRegistry userRegistry
```

_Address of userRegistry_

### commitments

```solidity
mapping(bytes32 => struct PreConfCommitmentStore.PreConfCommitment) commitments
```

_Commitment Hash -> Commitemnt
Only stores valid commitments_

### usedCommitments

```solidity
mapping(bytes32 => bool) usedCommitments
```

_Mapping to keep track of used PreConfCommitments_

### bids

```solidity
mapping(address => struct PreConfCommitmentStore.PreConfBid[]) bids
```

_Mapping from address to preconfbid list_

### commitmentss

```solidity
mapping(address => struct PreConfCommitmentStore.PreConfCommitment[]) commitmentss
```

_Mapping from address to commitmentss list_

### PreConfCommitment

_Struct for all the information around preconfirmations commitment_

```solidity
struct PreConfCommitment {
  address bidder;
  address commiter;
  uint64 bid;
  uint64 blockNumber;
  bytes32 bidHash;
  string txnHash;
  string commitmentHash;
  bytes bidSignature;
  bytes commitmentSignature;
}
```

### PreConfBid

_Struct for pre confirmation bid_

```solidity
struct PreConfBid {
  uint64 bid;
  uint64 blockNumber;
  bytes32 bidHash;
  string txnHash;
  bytes bidSignature;
}
```

### SignatureVerified

```solidity
event SignatureVerified(address signer, string txnHash, uint64 bid, uint64 blockNumber)
```

_Event to log successful verifications_

### fallback

```solidity
fallback() external payable
```

_fallback to revert all the calls._

### receive

```solidity
receive() external payable
```

_Revert if eth sent to this contract_

### onlyOracle

```solidity
modifier onlyOracle()
```

_Makes sure transaction sender is oracle_

### constructor

```solidity
constructor(address _providerRegistry, address _userRegistry, address _oracle) public
```

_Initializes the contract with the specified registry addresses, oracle, name, and version._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _providerRegistry | address | The address of the provider registry. |
| _userRegistry | address | The address of the user registry. |
| _oracle | address | The address of the oracle. |

### getBidsFor

```solidity
function getBidsFor(address adr) public view returns (struct PreConfCommitmentStore.PreConfBid[])
```

_Get the bids for a specific address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| adr | address | The address for which to retrieve bids. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct PreConfCommitmentStore.PreConfBid[] | An array of PreConfBid structures representing the bids made by the address. |

### getBidHash

```solidity
function getBidHash(string _txnHash, uint64 _bid, uint64 _blockNumber) public view returns (bytes32)
```

_Gives digest to be signed for bids_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _txnHash | string | transaction Hash. |
| _bid | uint64 | bid id. |
| _blockNumber | uint64 | block number |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | digest it returns a digest that can be used for signing bids |

### getPreConfHash

```solidity
function getPreConfHash(string _txnHash, uint64 _bid, uint64 _blockNumber, bytes32 _bidHash, string _bidSignature) public view returns (bytes32)
```

_Gives digest to be signed for pre confirmation_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _txnHash | string | transaction Hash. |
| _bid | uint64 | bid id. |
| _blockNumber | uint64 | block number. |
| _bidHash | bytes32 | hash of the bid. |
| _bidSignature | string |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | digest it returns a digest that can be used for signing bids. |

### retreiveCommitments

```solidity
function retreiveCommitments() public view returns (struct PreConfCommitmentStore.PreConfCommitment[])
```

_Retrieve a list of commitments._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct PreConfCommitmentStore.PreConfCommitment[] | An array of PreConfCommitment structures representing the commitments made. |

### retreiveCommitment

```solidity
function retreiveCommitment() public view returns (struct PreConfCommitmentStore.PreConfCommitment)
```

_Retrieve a commitment._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct PreConfCommitmentStore.PreConfCommitment | A PreConfCommitment structure representing the specified commitment. |

### verifyBid

```solidity
function verifyBid(uint64 bid, uint64 blockNumber, string txnHash, bytes bidSignature) public view returns (bytes32 messageDigest, address recoveredAddress, uint256 stake)
```

_Internal function to verify a bid_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| bid | uint64 | bid id. |
| blockNumber | uint64 | block number. |
| txnHash | string | transaction Hash. |
| bidSignature | bytes | bid signature. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| messageDigest | bytes32 | returns the bid hash for given bid id. |
| recoveredAddress | address | the address from the bid hash. |
| stake | uint256 | the stake amount of the address for bid id user. |

### storeCommitment

```solidity
function storeCommitment(uint64 bid, uint64 blockNumber, string txnHash, string commitmentHash, bytes bidSignature, bytes commitmentSignature) public returns (uint256)
```

_Store a commitment._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| bid | uint64 | The bid amount. |
| blockNumber | uint64 | The block number. |
| txnHash | string | The transaction hash. |
| commitmentHash | string | The commitment hash. |
| bidSignature | bytes | The signature of the bid. |
| commitmentSignature | bytes | The signature of the commitment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The new commitment count. |

### getCommitment

```solidity
function getCommitment(bytes32 commitmentHash) public view returns (struct PreConfCommitmentStore.PreConfCommitment)
```

_Get a commitment by its hash._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commitmentHash | bytes32 | The hash of the commitment. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct PreConfCommitmentStore.PreConfCommitment | A PreConfCommitment structure representing the commitment. |

### initiateSlash

```solidity
function initiateSlash(bytes32 commitmentHash) public
```

_Initiate a slash for a commitment._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commitmentHash | bytes32 | The hash of the commitment to be slashed. |

### initateReward

```solidity
function initateReward(bytes32 commitmentHash) public
```

_Initiate a reward for a commitment._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| commitmentHash | bytes32 | The hash of the commitment to be rewarded. |

### updateOracle

```solidity
function updateOracle(address newOracle) external
```

_Updates the address of the oracle._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOracle | address | The new oracle address. |

### updateProviderRegistry

```solidity
function updateProviderRegistry(address newProviderRegistry) public
```

_Updates the address of the provider registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newProviderRegistry | address | The new provider registry address. |

### updateUserRegistry

```solidity
function updateUserRegistry(address newUserRegistry) external
```

_Updates the address of the user registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newUserRegistry | address | The new user registry address. |

### bytes32ToHexString

```solidity
function bytes32ToHexString(bytes32 _bytes32) public pure returns (string)
```

### bytesToHexString

```solidity
function bytesToHexString(bytes _bytes) public pure returns (string)
```

### recoverAddress

```solidity
function recoverAddress(bytes32 messageDigest, bytes signature) public pure returns (address)
```

## ProviderRegistry

This contract is for provider registry and staking.

### minStake

```solidity
uint256 minStake
```

_Minimum stake required for registration_

### preConfirmationsContract

```solidity
address preConfirmationsContract
```

_Address of the pre-confirmations contract_

### providerRegistered

```solidity
mapping(address => bool) providerRegistered
```

_Mapping from provider address to whether they are registered or not_

### providerStakes

```solidity
mapping(address => uint256) providerStakes
```

_Mapping from provider addresses to their staked amount_

### ProviderRegistered

```solidity
event ProviderRegistered(address provider, uint256 stakedAmount)
```

_Event for provider registration_

### FundsDeposited

```solidity
event FundsDeposited(address provider, uint256 amount)
```

_Event for depositing funds_

### FundsSlashed

```solidity
event FundsSlashed(address provider, uint256 amount)
```

_Event for slashing funds_

### FundsRewarded

```solidity
event FundsRewarded(address provider, uint256 amount)
```

_Event for rewarding funds_

### fallback

```solidity
fallback() external payable
```

_Fallback function to revert all calls, ensuring no unintended interactions._

### receive

```solidity
receive() external payable
```

_Receive function is disabled for this contract to prevent unintended interactions.
Should be removed from here in case the registerAndStake function becomes more complex_

### constructor

```solidity
constructor(uint256 _minStake) public
```

_Constructor to initialize the contract with a minimum stake requirement._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _minStake | uint256 | The minimum stake required for provider registration. |

### onlyPreConfirmationEngine

```solidity
modifier onlyPreConfirmationEngine()
```

_Modifier to restrict a function to only be callable by the pre-confirmations contract._

### setPreconfirmationsContract

```solidity
function setPreconfirmationsContract(address contractAddress) external
```

_Sets the pre-confirmations contract address. Can only be called by the owner._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress | address | The address of the pre-confirmations contract. |

### registerAndStake

```solidity
function registerAndStake() public payable
```

_Register and stake function for providers._

### checkStake

```solidity
function checkStake(address provider) external view returns (uint256)
```

_Check the stake of a provider._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| provider | address | The address of the provider. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The staked amount for the provider. |

### depositFunds

```solidity
function depositFunds() external payable
```

_Deposit more funds into the provider's stake._

### slash

```solidity
function slash(uint256 amt, address provider, address payable user) external
```

_Slash funds from the provider and send the slashed amount to the user.
reenterancy not necessary but still putting here for precaution_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amt | uint256 | The amount to slash from the provider's stake. |
| provider | address | The address of the provider. |
| user | address payable | The address to transfer the slashed funds to. |

## UserRegistry

This contract is for user registry and staking.

### minStake

```solidity
uint256 minStake
```

_Minimum stake required for registration_

### preConfirmationsContract

```solidity
address preConfirmationsContract
```

_Address of the pre-confirmations contract_

### userRegistered

```solidity
mapping(address => bool) userRegistered
```

_Mapping for if user is registered_

### userStakes

```solidity
mapping(address => uint256) userStakes
```

_Mapping from user addresses to their staked amount_

### UserRegistered

```solidity
event UserRegistered(address user, uint256 stakedAmount)
```

_Event emitted when a user is registered with their staked amount_

### FundsRetrieved

```solidity
event FundsRetrieved(address user, uint256 amount)
```

_Event emitted when funds are retrieved from a user's stake_

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

### fallback

```solidity
fallback() external payable
```

_Fallback function to revert all calls, ensuring no unintended interactions._

### receive

```solidity
receive() external payable
```

_Receive function registers users and takes their stake
Should be removed from here in case the registerAndStake function becomes more complex_

### constructor

```solidity
constructor(uint256 _minStake) public
```

_Constructor to initialize the contract with a minimum stake requirement._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _minStake | uint256 | The minimum stake required for user registration. |

### onlyPreConfirmationEngine

```solidity
modifier onlyPreConfirmationEngine()
```

_Modifier to restrict a function to only be callable by the pre-confirmations contract._

### setPreconfirmationsContract

```solidity
function setPreconfirmationsContract(address contractAddress) public
```

_Sets the pre-confirmations contract address. Can only be called by the owner._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress | address | The address of the pre-confirmations contract. |

### registerAndStake

```solidity
function registerAndStake() public payable
```

_Internal function for user registration and staking._

### checkStake

```solidity
function checkStake(address user) external view returns (uint256)
```

_Check the stake of a user._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of the user. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The staked amount for the user. |

### retrieveFunds

```solidity
function retrieveFunds(address user, uint256 amt, address payable provider) external
```

_Retrieve funds from a user's stake (only callable by the pre-confirmations contract).
reenterancy not necessary but still putting here for precaution_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | The address of the user. |
| amt | uint256 | The amount to retrieve from the user's stake. |
| provider | address payable | The address to transfer the retrieved funds to. |

