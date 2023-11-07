// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IUserRegistry {
    struct PreConfCommitment {
        string txnHash;
        uint64 bid;
        uint64 blockNumber;
        string bidHash;
        string bidSignature;
        string commitmentHash;
        string commitmentSignature;
    }

    function registerAndStake() external payable;

    function checkStake(address user) external view returns (uint256);

    function retrieveFunds(
        address user,
        uint256 amt,
        address payable provider
    ) external;
}
