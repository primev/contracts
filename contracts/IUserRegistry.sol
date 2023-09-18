// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    function RegisterAndStake() external payable;
    function checkStake(address user) external view returns (uint256);
    function RetrieveFunds(address user, bytes32 commitmentHash, uint256 amt, address payable provider) external;

}
