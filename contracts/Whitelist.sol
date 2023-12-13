// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

// Contract that allows an admin to add/remove addresses from the whitelist,
// and allows whitelisted addresses to mint/burn native tokens.
contract Whitelist {
    address public admin;
    mapping(address => bool) public whitelistedAddresses;

    // Mint/burn precompile addresses.
    // See: https://github.com/primevprotocol/go-ethereum/blob/03ae168c6ac15dda8c5a3f123e2b9f3350aad613/core/vm/contracts.go
    address constant MINT = address(0x89);
    address constant BURN = address(0x90);

    constructor(address _admin) {
        require(_admin != address(0), "Admin address cannot be zero");
        admin = _admin;
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

    // Mints native tokens if the sender is whitelisted.
    // See geth fork precompile implementation:
    // https://github.com/primevprotocol/go-ethereum/blob/precompile-updates/core/vm/contracts_with_ctx.go#L83
    function mint(address _mintTo, uint256 _amount) external {
        require(isWhitelisted(msg.sender), "Sender is not whitelisted");
        bool success;
        (success, ) = MINT.call{value: 0, gas: gasleft()}(
            abi.encode(_mintTo, _amount) // TODO: confirm new schema works with precompile
        );
        require(success, "Native mint failed");
    }

    // Burns native tokens if the sender is whitelisted.
    // See geth fork precompile implementation: 
    // https://github.com/primevprotocol/go-ethereum/blob/precompile-updates/core/vm/contracts_with_ctx.go#L111
    function burn(address _burnFrom, uint256 _amount) external {
        require(isWhitelisted(msg.sender), "Sender is not whitelisted");
        bool success;
        (success, ) = BURN.call{value: 0, gas: gasleft()}(
            abi.encode(_burnFrom, _amount) 
        );
        require(success, "Native burn failed");
    }
}
