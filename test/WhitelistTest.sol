// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/Whitelist.sol";

// Tests the Whitelist contract.
// Note precompile interactions to mint/burn must be tested manually. 
contract WhitelistTest is Test {

    address admin;
    address normalUser;
    address addressInstance;
    Whitelist whitelist;

    function setUp() public {
        admin = address(this); // Contract deployer becomes admin
        normalUser = address(0x100);
        addressInstance = address(0x200);
        whitelist = new Whitelist();
    }

    function test_IsWhitelisted() public {
        assertFalse(whitelist.isWhitelisted(addressInstance));
        vm.prank(admin);
        whitelist.addToWhitelist(addressInstance);
        assertTrue(whitelist.isWhitelisted(addressInstance));
    }

    function test_AdminAddToWhitelist() public {
        vm.prank(admin);
        whitelist.addToWhitelist(addressInstance);
        assertTrue(whitelist.isWhitelisted(addressInstance));
    }

    function test_AdminRemoveFromWhitelist() public {
        vm.prank(admin);
        whitelist.addToWhitelist(addressInstance);
        assertTrue(whitelist.isWhitelisted(addressInstance));
        vm.prank(admin);
        whitelist.removeFromWhitelist(addressInstance);
        assertFalse(whitelist.isWhitelisted(addressInstance));
    }

    function test_RevertNormalUserAddToWhitelist() public {
        vm.prank(normalUser);
        vm.expectRevert("Only admin can call this function");
        whitelist.addToWhitelist(addressInstance);
    }

    function test_RevertNormalUserRemoveFromWhitelist() public {
        vm.prank(admin);
        whitelist.addToWhitelist(addressInstance);
        assertTrue(whitelist.isWhitelisted(addressInstance));
        vm.prank(normalUser);
        vm.expectRevert("Only admin can call this function");
        whitelist.removeFromWhitelist(addressInstance);
    }
}
