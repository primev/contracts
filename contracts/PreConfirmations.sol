// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

contract PreConfCommitmentStore {
    struct PreConfCommitment {
        string txnHash;
        uint64 bid;
        uint64 blockNumber;
        string bidHash;
        string bidSignature; 
        string commitmentSignature;
    }

    mapping(uint256 => PreConfCommitment) public commitments;

    // Updated function signature to include bidSignature
    function storeCommitment(
        string memory txnHash,
        uint64 bid,
        uint64 blockNumber,
        string memory bidHash,
        string memory bidSignature,
        string memory commitmentSignature
    ) public returns (uint256) {
        uint256 id = uint256(keccak256(abi.encodePacked(txnHash, bid, blockNumber, bidHash, bidSignature, commitmentSignature)));
        console.log("Recieved commitment");
        console.log("txnHash: %s", txnHash);
        console.log("bid: %s", bid);
        console.log("blockNumber: %s", blockNumber);
        console.log("bidHash: %s", bidHash);
        console.log("bidSignature: %s", bidSignature);
        console.log("commitmentSignature: %s", commitmentSignature);
        
        commitments[id] = PreConfCommitment(txnHash, bid, blockNumber, bidHash, bidSignature, commitmentSignature);
        return id;
    }

    function getCommitment(uint256 id) public view returns (PreConfCommitment memory) {
        return commitments[id];
    }
}
