// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProviderRegistry {
    function RegisterAndStake() external payable;
    function checkStake(address provider) external view returns (uint256);
    function depositFunds() external payable;
    function Slash(uint256 amt, address provider, address payable user) external;
    function reward(uint256 amt, address provider) external;
}
