// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProviderRegistry {
    function RegisterAndStake() external payable;
    function checkStake(address provider) external view returns (uint256);
    function depositFunds() external payable;
    function slash(uint256 amt, address provider) external;
    function reward(uint256 amt, address provider) external;
}
