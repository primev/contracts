// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/ValidatorRegistry.sol";

contract ValidatorRegistryTest is Test {
    ValidatorRegistry public validatorRegistry;
    address public owner;
    address public user1;
    address public user2;

    uint256 public constant MIN_STAKE = 1 ether;
    address public constant SLASH_RECIPIENT = address(0x789);

    event SelfStake(address indexed staker, uint256 amount);
    event StakeSplit(address indexed staker, address[] recipients, uint256 totalAmount);
    event StakeWithdrawn(address indexed staker, uint256 amount);

    function setUp() public {
        owner = address(this);
        user1 = address(0x123);
        user2 = address(0x456);

        validatorRegistry = new ValidatorRegistry(MIN_STAKE, SLASH_RECIPIENT);
    }

    function testSelfStake() public {
        vm.deal(user1, 10 ether);

        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit SelfStake(user1, MIN_STAKE);
        validatorRegistry.selfStake{value: MIN_STAKE}();
        vm.stopPrank();

        assertEq(validatorRegistry.stakedBalances(user1), MIN_STAKE);
        assertTrue(validatorRegistry.isStaked(user1));
    }

    function testSplitStake() public {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        uint256 totalAmount = 2 ether;
        vm.deal(address(this), totalAmount);

        vm.expectEmit(true, true, true, true);
        emit StakeSplit(address(this), recipients, totalAmount);
        validatorRegistry.splitStake{value: totalAmount}(recipients);

        assertEq(validatorRegistry.stakedBalances(user1), 1 ether);
        assertEq(validatorRegistry.stakedBalances(user2), 1 ether);
        assertTrue(validatorRegistry.isStaked(user1));
        assertTrue(validatorRegistry.isStaked(user2));
    }

    function testWithdrawStake() public {
        testSelfStake();

        vm.startPrank(user1);
        address[] memory fromAddrs = new address[](1);
        fromAddrs[0] = user1;

        vm.expectEmit(true, true, true, true);
        emit StakeWithdrawn(user1, MIN_STAKE);
        validatorRegistry.withdraw(fromAddrs);
        vm.stopPrank();

        assertEq(validatorRegistry.stakedBalances(user1), 0);
        assertFalse(validatorRegistry.isStaked(user1));
    }

    function testFailWithdrawWithInsufficientStake() public {
        vm.startPrank(user2);
        address[] memory fromAddrs = new address[](1);
        fromAddrs[0] = user2;

        // This should revert because user2 has no stake
        validatorRegistry.withdraw(fromAddrs);
        vm.stopPrank();
    }

    function testFailUnauthorizedWithdraw() public {
        uint256 stakeAmount = 1 ether;
        vm.deal(user1, stakeAmount);

        vm.startPrank(user1);
        validatorRegistry.selfStake{value: stakeAmount}();
        vm.stopPrank();
        assertTrue(validatorRegistry.isStaked(user1));

        console.log("Staked balance of user1:", validatorRegistry.stakedBalances(user1));
        console.log("Stake originator of user1:", validatorRegistry.stakeOriginators(user1));

        vm.startPrank(user2);
        address[] memory fromAddrs = new address[](1);
        fromAddrs[0] = user1;
        validatorRegistry.withdraw(fromAddrs);
        vm.expectRevert("Not authorized to withdraw. Must be stake originator or EOA who's staked");
        vm.stopPrank();
    }
}
