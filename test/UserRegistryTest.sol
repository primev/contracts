// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {UserRegistry} from "../contracts/UserRegistry.sol";

contract UserRegistryTest is Test {
    uint256 testNumber;
    UserRegistry internal userRegistry;
    uint16 internal feePercent;
    uint256 internal minStake;
    address internal user;
    address internal feeRecipient;

    /// @dev Event emitted when a user is registered with their staked amount
    event UserRegistered(address indexed user, uint256 stakedAmount);

    function setUp() public {
        testNumber = 42;
        feePercent = 10;
        minStake = 1e18 wei;
        feeRecipient = vm.addr(9);

        userRegistry = new UserRegistry(minStake, feeRecipient, feePercent);

        user = vm.addr(1);
        vm.deal(user, 100 ether);
        vm.deal(address(this), 100 ether);
    }

    function test_VerifyInitialContractState() public {
        assertEq(userRegistry.minStake(), 1e18 wei);
        assertEq(userRegistry.feeRecipient(), feeRecipient);
        assertEq(userRegistry.feePercent(), feePercent);
        assertEq(userRegistry.preConfirmationsContract(), address(0));
        assertEq(userRegistry.userRegistered(user), false);
    }

    function testFail_UserStakeAndRegisterMinStake() public {
        vm.prank(user);
        vm.expectRevert(bytes(""));
        userRegistry.registerAndStake{value: 1 wei}();
    }

    function test_UserStakeAndRegister() public {
        vm.prank(user);
        vm.expectEmit(true, false, false, true);

        emit UserRegistered(user, 1e18 wei);

        userRegistry.registerAndStake{value: 1e18 wei}();

        bool isUserRegistered = userRegistry.userRegistered(user);
        assertEq(isUserRegistered, true);

        uint256 userStakeStored = userRegistry.checkStake(user);
        assertEq(userStakeStored, 1e18 wei);
    }

    function testFail_UserStakeAndRegisterAlreadyRegistered() public {
        vm.prank(user);
        userRegistry.registerAndStake{value: 2e18 wei}();
        vm.expectRevert(bytes(""));
        userRegistry.registerAndStake{value: 1 wei}();
    }

    function testFail_receive() public {
        vm.prank(user);
        vm.expectRevert(bytes(""));
        (bool success, ) = address(userRegistry).call{value: 1 wei}("");
        require(success, "couldn't transfer to user");
    }

    function testFail_fallback() public {
        vm.prank(user);
        vm.expectRevert(bytes(""));
        (bool success, ) = address(userRegistry).call{value: 1 wei}("");
        require(success, "couldn't transfer to user");
    }

    function test_SetNewFeeRecipient() public {
        address newRecipient = vm.addr(2);
        vm.prank(address(this));
        userRegistry.setNewFeeRecipient(newRecipient);

        assertEq(userRegistry.feeRecipient(), newRecipient);
    }

    function testFail_SetNewFeeRecipient() public {
        address newRecipient = vm.addr(2);
        vm.expectRevert(bytes(""));
        userRegistry.setNewFeeRecipient(newRecipient);
    }

    function test_SetNewFeePercent() public {
        vm.prank(address(this));
        userRegistry.setNewFeePercent(uint16(25));

        assertEq(userRegistry.feePercent(), uint16(25));
    }

    function testFail_SetNewFeePercent() public {
        vm.expectRevert(bytes(""));
        userRegistry.setNewFeePercent(uint16(25));
    }

    function test_SetPreConfContract() public {
        vm.prank(address(this));
        address newPreConfContract = vm.addr(3);
        userRegistry.setPreconfirmationsContract(newPreConfContract);

        assertEq(userRegistry.preConfirmationsContract(), newPreConfContract);
    }

    function testFail_SetPreConfContract() public {
        vm.prank(address(this));
        vm.expectRevert(bytes(""));
        userRegistry.setPreconfirmationsContract(address(0));
    }

    function test_shouldRetrieveFunds() public {
        userRegistry.setPreconfirmationsContract(address(this));
        vm.prank(user);
        userRegistry.registerAndStake{value: 2 ether}();
        address provider = vm.addr(4);

        userRegistry.retrieveFunds(user, 1 ether, payable(provider));
        uint256 providerAmount = userRegistry.providerAmount(provider);
        uint256 feeRecipientAmount = userRegistry.feeRecipientAmount();

        assertEq(providerAmount, 900000000000000000);
        assertEq(feeRecipientAmount, 100000000000000000);
        assertEq(userRegistry.userStakes(user), 1 ether);
    }

    function test_shouldRetrieveFundsWithoutFeeRecipient() public {
        vm.prank(address(this));
        uint256 feerecipientValueBefore = userRegistry.feeRecipientAmount();

        userRegistry.setNewFeeRecipient(address(0));
        userRegistry.setPreconfirmationsContract(address(this));

        vm.prank(user);
        userRegistry.registerAndStake{value: 2 ether}();
        address provider = vm.addr(4);

        userRegistry.retrieveFunds(user, 1 ether, payable(provider));

        uint256 feerecipientValueAfter = userRegistry.feeRecipientAmount();
        uint256 providerAmount = userRegistry.providerAmount(provider);

        assertEq(providerAmount, 900000000000000000);
        assertEq(feerecipientValueAfter, feerecipientValueBefore);

        assertEq(userRegistry.userStakes(user), 1 ether);
    }

    function testFail_shouldRetrieveFundsNotPreConf() public {
        vm.prank(user);
        userRegistry.registerAndStake{value: 2 ether}();
        address provider = vm.addr(4);
        vm.expectRevert(bytes(""));
        userRegistry.retrieveFunds(user, 1 ether, payable(provider));
    }

    function testFail_shouldRetrieveFundsGreaterThanStake() public {
        vm.prank(address(this));
        userRegistry.setPreconfirmationsContract(address(this));

        vm.prank(user);
        userRegistry.registerAndStake{value: 2 ether}();

        address provider = vm.addr(4);
        vm.expectRevert(bytes(""));
        vm.prank(address(this));

        userRegistry.retrieveFunds(user, 3 ether, payable(provider));
    }

    function test_withdrawFeeRecipientAmount() public {
        userRegistry.setPreconfirmationsContract(address(this));
        vm.prank(user);
        userRegistry.registerAndStake{value: 2 ether}();
        address provider = vm.addr(4);
        uint256 balanceBefore = feeRecipient.balance;
        userRegistry.retrieveFunds(user, 1 ether, payable(provider));
        userRegistry.withdrawFeeRecipientAmount();
        uint256 balanceAfter = feeRecipient.balance;
        assertEq(balanceAfter - balanceBefore, 100000000000000000);
        assertEq(userRegistry.feeRecipientAmount(), 0);
    }

    function testFail_withdrawFeeRecipientAmount() public {
        userRegistry.setPreconfirmationsContract(address(this));
        userRegistry.withdrawFeeRecipientAmount();
    }

    function test_withdrawProviderAmount() public {
        userRegistry.setPreconfirmationsContract(address(this));
        vm.prank(user);
        userRegistry.registerAndStake{value: 5 ether}();
        address provider = vm.addr(4);
        uint256 balanceBefore = address(provider).balance;
        userRegistry.retrieveFunds(user, 2 ether, payable(provider));
        userRegistry.withdrawProviderAmount(payable(provider));
        uint256 balanceAfter = address(provider).balance;
        assertEq(balanceAfter - balanceBefore, 1800000000000000000);
        assertEq(userRegistry.providerAmount(provider), 0);
    }

    function testFail_withdrawProviderAmount() public {
        userRegistry.setPreconfirmationsContract(address(this));
        vm.prank(user);
        userRegistry.registerAndStake{value: 5 ether}();
        address provider = vm.addr(4);
        userRegistry.withdrawProviderAmount(payable(provider));
    }

    function test_withdrawStakedAmount() public {
        userRegistry.setPreconfirmationsContract(address(this));
        vm.prank(user);
        userRegistry.registerAndStake{value: 5 ether}();
        uint256 balanceBefore = address(user).balance;
        vm.prank(user);
        userRegistry.withdrawStakedAmount(payable(user));
        uint256 balanceAfter = address(user).balance;
        assertEq(balanceAfter - balanceBefore, 5 ether);
        assertEq(userRegistry.userStakes(user), 0);
    }

    function testFail_withdrawStakedAmountNotOwner() public {
        userRegistry.setPreconfirmationsContract(address(this));
        vm.prank(user);
        userRegistry.registerAndStake{value: 5 ether}();
        userRegistry.withdrawStakedAmount(payable(user));
    }

    function testFail_withdrawStakedAmountStakeZero() public {
        userRegistry.setPreconfirmationsContract(address(this));
        vm.prank(user);
        userRegistry.withdrawStakedAmount(payable(user));
    }

    function test_withdrawProtocolFee() public {
        address provider = vm.addr(4);
        userRegistry.setPreconfirmationsContract(address(this));
        userRegistry.setNewFeeRecipient(address(0));
        vm.prank(user);
        userRegistry.registerAndStake{value: 5 ether}();
        uint256 balanceBefore = address(user).balance;
        userRegistry.retrieveFunds(user, 2 ether, payable(provider));
        vm.prank(userRegistry.owner());
        userRegistry.withdrawProtocolFee(payable(address(user)));
        uint256 balanceAfter = address(user).balance;
        assertEq(balanceAfter - balanceBefore, 200000000000000000);
        assertEq(userRegistry.protocolFeeAmount(), 0);
    }

    function testFail_withdrawProtocolFee() public {
        userRegistry.setPreconfirmationsContract(address(this));
        userRegistry.setNewFeeRecipient(address(0));
        vm.prank(user);
        userRegistry.registerAndStake{value: 5 ether}();
        vm.prank(userRegistry.owner());
        userRegistry.withdrawProtocolFee(payable(address(user)));
    }

    function testFail_withdrawProtocolFeeNotOwner() public {
        userRegistry.setPreconfirmationsContract(address(this));
        userRegistry.setNewFeeRecipient(address(0));
        vm.prank(user);
        userRegistry.registerAndStake{value: 5 ether}();
        userRegistry.withdrawProtocolFee(payable(address(user)));
    }
}
