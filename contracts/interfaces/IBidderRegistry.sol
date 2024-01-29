// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

interface IBidderRegistry {
    struct PreConfCommitment {
        string txnHash;
        uint64 bid;
        uint64 blockNumber;
        string bidHash;
        string bidSignature;
        string commitmentHash;
        string commitmentSignature;
    }


    struct BidState {
        uint64 bidAmt;
        State state;
    }

    enum State {
        UnPreConfirmed,
        PreConfirmed,
        Withdrawn
    }

    function prepay() external payable;

    function IdempotentBidFundsMovement(bytes32 commitmentDigest, uint64 bid, address bidder) external;
    
    function getAllowance(address bidder) external view returns (uint256);

    function retrieveFunds(
        address bidder,
        uint256 amt,
        address payable provider
    ) external;
}
