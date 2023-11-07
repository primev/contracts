// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IProviderRegistry {
    function registerAndStake() external payable;

    function checkStake(address provider) external view returns (uint256);

    function depositFunds() external payable;

    function slash(
        uint256 amt,
        address provider,
        address payable user
    ) external;
}
