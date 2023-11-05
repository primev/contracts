# Solidity API

## UserRegistry

This contract is for user registry and staking.

### PRECISION

```solidity
uint256 PRECISION
```

_For improved precision_

### PERCENT

```solidity
uint256 PERCENT
```

### feePercent

```solidity
uint16 feePercent
```

_Fee percent that would be taken by protocol when provider is slashed_

### minStake

```solidity
uint256 minStake
```

_Minimum stake required for registration_

### feeRecipientAmount

```solidity
uint256 feeRecipientAmount
```

_Amount assigned to feeRecipient_

### protocolFeeAmount

```solidity
uint256 protocolFeeAmount
```

_protocol fee, left over amount when there is no fee recipient assigned_

### preConfirmationsContract

```solidity
address preConfirmationsContract
```

_Address of the pre-confirmations contract_

### feeRecipient

```solidity
address feeRecipient
```

_Fee recipient_

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

### providerAmount

```solidity
mapping(address => uint256) providerAmount
```

_Amount assigned to users_

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
constructor(uint256 _minStake, address _feeRecipient, uint16 _feePercent) public
```

_Constructor to initialize the contract with a minimum stake requirement._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _minStake | uint256 | The minimum stake required for user registration. |
| _feeRecipient | address | The address that receives fee |
| _feePercent | uint16 | The fee percentage for protocol |

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

### setNewFeeRecipient

```solidity
function setNewFeeRecipient(address newFeeRecipient) external
```

Sets the new fee recipient

_onlyOwner restriction_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newFeeRecipient | address | The address to transfer the slashed funds to. |

### setNewFeePercent

```solidity
function setNewFeePercent(uint16 newFeePercent) external
```

Sets the new fee recipient

_onlyOwner restriction_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newFeePercent | uint16 | this is the new fee percent |

### withdrawFeeRecipientAmount

```solidity
function withdrawFeeRecipientAmount() external
```

### withdrawProviderAmount

```solidity
function withdrawProviderAmount(address payable provider) external
```

### withdrawStakedAmount

```solidity
function withdrawStakedAmount(address payable user) external
```

### withdrawProtocolFee

```solidity
function withdrawProtocolFee(address payable user) external
```

