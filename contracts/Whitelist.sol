// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

contract Whitelist {
    address public admin;
    mapping(address => bool) public whitelistedAddresses;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function addToWhitelist(address _address) external onlyAdmin {
        whitelistedAddresses[_address] = true;
    }

    function removeFromWhitelist(address _address) external onlyAdmin {
        whitelistedAddresses[_address] = false;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelistedAddresses[_address];
    }
}
