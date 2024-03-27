pragma solidity ^0.8.20;

interface IOracle {
    function getCurrentWindow() external view returns (uint256);
}
