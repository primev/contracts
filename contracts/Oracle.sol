// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PreConfCommitmentStore} from "./PreConfirmations.sol";
import {IProviderRegistry} from "./interfaces/IProviderRegistry.sol";
import {IPreConfCommitmentStore} from "./interfaces/IPreConfirmations.sol";
import {IBidderRegistry} from "./interfaces/IBidderRegistry.sol";
import {IBlockTracker} from "./interfaces/IBlockTracker.sol";

/// @title Oracle Contract
/// @author Kartik Chopra
/// @notice This contract is for fetching L1 Ethereum Block Data

/**
 * @title Oracle - A contract for Fetching L1 Block Builder Info and Block Data.
 * @dev This contract serves as an oracle to fetch and process Ethereum Layer 1 block data.
 */
contract Oracle is Ownable {
    /// @dev Maps builder names to their respective Ethereum addresses.
    mapping(string => address) public blockBuilderNameToAddress;

    // To shutup the compiler
    /// @dev Empty receive function to silence compiler warnings about missing payable functions.
    receive() external payable {
        // Empty receive function
    }

    /**
     * @dev Fallback function to revert all calls, ensuring no unintended interactions.
     */
    fallback() external payable {
        revert("Invalid call");
    }

    /// @dev Reference to the PreConfCommitmentStore contract interface.
    IPreConfCommitmentStore private preConfContract;

    /// @dev Reference to the BlockTracker contract interface.
    IBlockTracker private blockTrackerContract;

    /**
     * @dev Constructor to initialize the contract with a PreConfirmations contract.
     * @param _preConfContract The address of the pre-confirmations contract.
     * @param _owner Owner of the contract, explicitly needed since contract is deployed with create2 factory.
     */
    constructor(
        address _preConfContract,
        address _blockTrackerContract,
        address _owner
    ) Ownable() {
        preConfContract = IPreConfCommitmentStore(_preConfContract);
        blockTrackerContract = IBlockTracker(_blockTrackerContract);
        _transferOwnership(_owner);
    }

    /// @dev Event emitted when a commitment is processed.
    event CommitmentProcessed(bytes32 commitmentHash, bool isSlash);

    /**
     * @dev Allows the owner to add a new builder address.
     * @param builderName The name of the block builder as it appears on extra data.
     * @param builderAddress The Ethereum address of the builder.
     */
    function addBuilderAddress(
        string memory builderName,
        address builderAddress
    ) external onlyOwner {
        blockBuilderNameToAddress[builderName] = builderAddress;
    }

    /**
     * @dev Returns the builder's address corresponding to the given name.
     * @param builderNameGrafiti The name (or graffiti) of the block builder.
     */
    function getBuilder(
        string calldata builderNameGrafiti
    ) external view returns (address) {
        return blockBuilderNameToAddress[builderNameGrafiti];
    }

    // Function to receive and process the block data (this would be automated in a real-world scenario)
    /**
     * @dev Processes a builder's commitment for a specific block number.
     * @param commitmentIndex The id of the commitment in the PreConfCommitmentStore.
     * @param blockNumber The block number to be processed.
     * @param blockBuilderName The name of the block builder.
     * @param isSlash Determines whether the commitment should be slashed or rewarded.
     */
    function processBuilderCommitmentForBlockNumber(
        bytes32 commitmentIndex,
        uint256 blockNumber,
        string calldata blockBuilderName,
        bool isSlash,
        uint256 residualBidPercentAfterDecay
    ) external onlyOwner {
        // Check graffiti against registered builder IDs
        address builder = blockBuilderNameToAddress[blockBuilderName];
        require(
            residualBidPercentAfterDecay <= 100,
            "Residual bid after decay cannot be greater than 100 percent"
        );
        IPreConfCommitmentStore.PreConfCommitment
            memory commitment = preConfContract.getCommitment(commitmentIndex);
        if (
            commitment.commiter == builder &&
            commitment.blockNumber == blockNumber
        ) {
            processCommitment(
                commitmentIndex,
                isSlash,
                residualBidPercentAfterDecay
            );
        }
    }

    /**
     * @dev unlocks funds to the bidders assosciated with BidIDs in the input array.
     * @param bidIDs The array of BidIDs to unlock funds for.
     */
    function unlockFunds(uint256 window, bytes32[] memory bidIDs) external onlyOwner {
        for (uint256 i = 0; i < bidIDs.length; i++) {
            preConfContract.unlockBidFunds(window, bidIDs[i]);
        }
    }

    /**
     * @dev Internal function to process a commitment, either slashing or rewarding based on the commitment's state.
     * @param commitmentIndex The id of the commitment to be processed.
     * @param isSlash Determines if the commitment should be slashed or rewarded.
     */
    function processCommitment(
        bytes32 commitmentIndex,
        bool isSlash,
        uint256 residualBidPercentAfterDecay
    ) private {
        // processing commitment after window has been settled
        uint256 windowToSettle = blockTrackerContract.getCurrentWindow() - 1;
        if (isSlash) {
            preConfContract.initiateSlash(
                windowToSettle,
                commitmentIndex,
                residualBidPercentAfterDecay
            );
        } else {
            preConfContract.initiateReward(
                windowToSettle,
                commitmentIndex,
                residualBidPercentAfterDecay
            );
        }
        // Emit an event that a commitment has been processed
        emit CommitmentProcessed(commitmentIndex, isSlash);
    }
}
