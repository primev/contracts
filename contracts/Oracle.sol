// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PreConfCommitmentStore} from "./PreConfirmations.sol";
import {IProviderRegistry} from "./interfaces/IProviderRegistry.sol";
import {IPreConfCommitmentStore} from './interfaces/IPreConfirmations.sol';
/// @title Oracle Contract
/// @author Kartik Chopra
/// @notice This contract is for fetching L1 Ethereum Block Data

/**
 * @title Oracle - A contract for Fetching L1 Block Builder Info and Block Data.
 */
contract Oracle is Ownable {

    mapping(string => address) public blockBuilderNameToAddress;

    uint256 public nextRequestedBlockNumber;

    function getNextRequestedBlockNumber() external view returns (uint256) {
        return nextRequestedBlockNumber;
    }

    // To shutup the compiler
    // TODO(@ckartik): remove or make Oracle non-payable
    receive() external payable {
    // Empty receive function
    }

    /**
     * @dev Fallback function to revert all calls, ensuring no unintended interactions.
     */
    fallback() external payable {
        revert("Invalid call");
    }

    IPreConfCommitmentStore private preConfContract;

    /**
     * @dev Constructor to initialize the contract with a a preconf contract.
     * @param _preConfContract The address of the pre-confirmations contract.
     * @param _owner Owner of the contract, explicitly needed since contract is deployed w/ create2 factory.
     */
    constructor(
    address _preConfContract,
    uint256 _nextRequestedBlockNumber,
    address _owner
    ) Ownable() {
        preConfContract = IPreConfCommitmentStore(_preConfContract);
        nextRequestedBlockNumber = _nextRequestedBlockNumber;
        _transferOwnership(_owner);
    }

    // Event to signal the processing of a commitment
    event CommitmentProcessed(bytes32 commitmentHash, bool isSlash);

    function addBuilderAddress(string memory builderName, address builderAddress) external onlyOwner {
        blockBuilderNameToAddress[builderName] = builderAddress;
    }


    function getBuilder(string calldata builderNameGrafiti) external view returns (address) {
        return blockBuilderNameToAddress[builderNameGrafiti];
    }

    // Function to receive and process the block data (this would be automated in a real-world scenario)
    // TODO(@ckartik): Should restrict who can make this call
    function processBuilderCommitmentForBlockNumber(
        bytes32 commitmentIndex,
        uint256 blockNumber,
        string calldata blockBuilderName,
        bool isSlash
    ) external onlyOwner {
        // Check grafiti against registered builder IDs
        address builder = blockBuilderNameToAddress[blockBuilderName];
        
        IPreConfCommitmentStore.PreConfCommitment memory commitment = preConfContract.getCommitment(commitmentIndex);
        if (commitment.commiter == builder && commitment.blockNumber == blockNumber) {
                processCommitment(commitmentIndex, isSlash);
        }

    }

    function setNextBlock(uint64 newBlockNumber) external onlyOwner {
        nextRequestedBlockNumber = newBlockNumber;
    }

    function moveToNextBlock() external onlyOwner {
        nextRequestedBlockNumber++;
    }

    // Function to simulate the processing of a commitment (initiate a slash or a reward)
    function processCommitment(bytes32 commitmentIndex, bool isSlash) private {
        if (isSlash) {
            preConfContract.initiateSlash(commitmentIndex);
        } else {
            preConfContract.initateReward(commitmentIndex);
        }
        // Emit an event that a commitment has been processed
        emit CommitmentProcessed(commitmentIndex, isSlash);
    }

}
