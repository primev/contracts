// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/caontracts/utils/ReentrancyGuard.sol";
import {PreConfCommitmentStore} from "./PreConfirmations.sol";
import {IProviderRegistry} from "./interfaces/IProviderRegistry.sol";

/// @title Oracle Contract
/// @author Kartik Chopra
/// @notice This contract is for fetching L1 Ethereum Block Data

/**
 * @title PreConfCommitmentStore - A contract for managing preconfirmation commitments and bids.
 * @notice This contract allows users to make precommitments and bids and provides a mechanism for the oracle to verify and process them.
 * @dev This contract should not be used in production as it is for demonstration purposes.
 */
contract Oracle is Ownable {
    
    /**
     * @dev Fallback function to revert all calls, ensuring no unintended interactions.
     */
    fallback() external payable {
        revert("Invalid call");
    }

    IPreConfirmations private preConfContract;

    // Address of the PreConfirmations contract
    address public preConfirmationsContract;

    /**
     * @dev Constructor to initialize the contract with a a preconf contract.
     * @param _preConfContract The address of the pre-confirmations contract.
     */
    constructor(
    address _preConfContract
    ) Ownable(msg.sender) {
        preConfContract = IPreConfirmations(_preConfContract);
    }


    // Event to request block data
    event BlockDataRequested(uint256 blockNumber);

    // Event to signal the reception of block data
    event BlockDataReceived(
        bytes32[] txnList,
        uint256 blockNumber,
        string blockBuilderName
    );

    // Event to signal the processing of a commitment
    event CommitmentProcessed(bytes32 commitmentHash, bool isSlash);

    // Function to request the block data
    function requestBlockData(uint256 blockNumber) external {
        // Emit an event that data request has been made
        emit BlockDataRequested(blockNumber);
    }

    // Function to receive and process the block data (this would be automated in a real-world scenario)
    // TODO(@ckartik): Should restrict who can make this call
    function receiveBlockData(
        bytes32[] calldata txnList,
        uint256 blockNumber,
        string calldata blockBuilderName
    ) external {
        // Emit an event that the block data has been received
        emit BlockDataReceived(txnList, blockNumber, blockBuilderName);
        // Placeholder: Process the block data and determine the commitment's validity
        // For demonstration, we'll call this with a dummy commitment hash and isSlash flag
    }

    // Function to simulate the processing of a commitment (initiate a slash or a reward)
    function processCommitment(bytes32 commitmentHash, bool isSlash) external {
        if (isSlash) {
            preConfContract.initiateSlash(commitmentHash);
        } else {
            preConfContract.initateReward(commitmentHash);
        }
        // Emit an event that a commitment has been processed
        emit CommitmentProcessed(commitmentHash, isSlash);
    }

}
