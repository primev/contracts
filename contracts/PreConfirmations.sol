// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PreConfCommitmentStore {
    
    struct PreConfCommitment {
        string txnHash;
        uint64 bid;
        uint64 blockNumber;
        string bidHash; // Hex Encoded Hash
        string signature; // Hex Encoded Signature
        uint256 timestamp;
    }

    // Mapping from a user address to their PreConfCommitment
    mapping(address => PreConfCommitment) public commitments;

    // Set a commitment
    function setCommitment(
        string memory _txnHash, 
        uint64 _bid, 
        uint64 _blockNumber, 
        string memory _bidHash, 
        string memory _signature
    ) public {
        PreConfCommitment memory newCommitment = PreConfCommitment({
            txnHash: _txnHash,
            bid: _bid,
            blockNumber: _blockNumber,
            bidHash: _bidHash,
            signature: _signature,
            timestamp: block.timestamp
        });

        commitments[msg.sender] = newCommitment;
    }

    // Get a commitment
    function getCommitment(address _user) public view returns (
        string memory, 
        uint64, 
        uint64, 
        string memory, 
        string memory, 
        uint256
    ) {
        PreConfCommitment memory commitment = commitments[_user];
        return (
            commitment.txnHash, 
            commitment.bid, 
            commitment.blockNumber, 
            commitment.bidHash, 
            commitment.signature, 
            commitment.timestamp
        );
    }
}

