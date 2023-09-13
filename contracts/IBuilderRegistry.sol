pragma solidity ^0.8.0;

interface IBuilderRegistry {
    function isBuilderRegistered(address builderAddress) external view returns (bool);
}