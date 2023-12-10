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
     */
    constructor(
    address _preConfContract,
    uint256 _nextRequestedBlockNumber
    ) Ownable() {
        preConfContract = IPreConfCommitmentStore(_preConfContract);
        nextRequestedBlockNumber = _nextRequestedBlockNumber;
    }

    // mapping of txns to bool to check if txns exists
    // Stores all proccessed txns for onw
    // TODO(@ckartik): This may be too restricvie in the log run as an appraoch
    mapping(string => bool) txnHashes;


    // Event to request block data
    event BlockDataRequested(uint256 blockNumber);

    // Event to signal the reception of block data
    event BlockDataReceived(
        string[] txnList,
        uint256 blockNumber,
        string blockBuilderName
    );

    // Event to signal the processing of a commitment
    event CommitmentProcessed(bytes32 commitmentHash, bool isSlash);

    function addBuilderAddress(string memory builderName, address builderAddress) external onlyOwner {
        blockBuilderNameToAddress[builderName] = builderAddress;
    }

    // Function to request the block data
    function requestBlockData(uint256 blockNumber) external {
        // Emit an event that data request has been made
        emit BlockDataRequested(blockNumber);
    }

    // Function to receive and process the block data (this would be automated in a real-world scenario)
    // TODO(@ckartik): Should restrict who can make this call
    function receiveBlockData(
        string[] calldata txnList,
        uint256 blockNumber,
        string calldata blockBuilderName
    ) external {
        // Emit an event that the block data has been received
        emit BlockDataReceived(txnList, blockNumber, blockBuilderName);
        address builder = blockBuilderNameToAddress[blockBuilderName];
        
        for (uint256 i = 0; i < txnList.length; i++) {
            txnHashes[txnList[i]] = true;
        }

        // Placeholder: Process the block data and determine the commitment's validity
        // For demonstration, we'll call this with a dummy commitment hash and isSlash flag
        bytes32[] memory commitmentHashes = preConfContract.getCommitmentsByBlockNumber(blockNumber);
        for (uint256 i = 0; i < commitmentHashes.length; i++) {
            IPreConfCommitmentStore.PreConfCommitment memory commitment = preConfContract.getCommitment(commitmentHashes[i]);
            if (commitment.commiter == builder) {
                if (txnHashes[commitment.txnHash]){
                    this.processCommitment(commitmentHashes[i], false);
                }
                else {
                    this.processCommitment(commitmentHashes[i], true);
                }
            }
        }

        if (nextRequestedBlockNumber <= blockNumber) {
            nextRequestedBlockNumber = blockNumber + 1;
        }
    }

    // Function to simulate the processing of a commitment (initiate a slash or a reward)
    function processCommitment(bytes32 commitmentIndex, bool isSlash) external {
        if (isSlash) {
            preConfContract.initiateSlash(commitmentIndex);
        } else {
            preConfContract.initateReward(commitmentIndex);
        }
        // Emit an event that a commitment has been processed
        emit CommitmentProcessed(commitmentIndex, isSlash);
    }

}
