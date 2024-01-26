// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../../contracts/standard-bridge/L1Gateway.sol";

contract L1GatewayTest is Test {
    L1Gateway l1Gateway;
    address owner;
    address relayer;
    address bridgeUser;
    uint256 finalizationFee;
    uint256 counterpartyFee;

    function setUp() public {
        owner = address(this); // Original contract deployer as owner
        relayer = address(0x78);
        bridgeUser = address(0x101);
        finalizationFee = 0.1 ether;
        counterpartyFee = 0.05 ether;
        l1Gateway = new L1Gateway(owner, relayer, finalizationFee, counterpartyFee);
    }

    function test_ConstructorSetsVariablesCorrectly() public {
        assertEq(l1Gateway.owner(), owner);
        assertEq(l1Gateway.relayer(), relayer);
        assertEq(l1Gateway.finalizationFee(), finalizationFee);
        assertEq(l1Gateway.counterpartyFee(), counterpartyFee);
    }

    // Expected event signature emitted in initiateTransfer()
    event TransferInitiated(
        address indexed sender, address indexed recipient, uint256 amount, uint256 transferIdx);

    function test_InitiateTransfer() public {
        vm.deal(bridgeUser, 100 ether);
        uint256 amount = 7 ether;

        // Initial assertions
        assertEq(address(bridgeUser).balance, 100 ether);
        assertEq(l1Gateway.transferIdx(), 0);

        // Set up expectation for event
        vm.expectEmit(true, true, true, true);
        emit TransferInitiated(bridgeUser, bridgeUser, amount, 1);

        // Call function as bridgeUser
        vm.prank(bridgeUser);
        uint256 returnedIdx = l1Gateway.initiateTransfer{value: amount}(bridgeUser, amount);

        // Assertions after call
        assertEq(address(bridgeUser).balance, 93 ether); 
        assertEq(l1Gateway.transferIdx(), 1);
        assertEq(returnedIdx, 1);
    }


    // function test_Fund() public {
    //     uint256 amount = 7 ether;
    //     address thisContract = address(this);

    //     l1Gateway._fund(amount, toFund){value: amount};
    //     assertEq(address(toFund).balance, amount);
    // }

    // function test_RevertOnInsufficientBalanceForFund() public {
    //     uint256 amount = 1 ether;
    //     address toFund = address(this);

    //     vm.expectRevert("Insufficient contract balance");
    //     l1Gateway._fund(amount, toFund);
    // }

    // function test_RevertOnIncorrectEtherValueSent() public {
    //     uint256 amount = 1 ether;
        
    //     vm.expectRevert("Incorrect Ether value sent");
    //     l1Gateway._decrementMsgSender(amount);
    // }

    // function test_OnlyRelayerCanFinalizeTransfer() public {
    //     address recipient = address(0x3);
    //     uint256 amount = 2 ether; // includes finalization fee
    //     uint256 counterpartyIdx = 1;

    //     vm.prank(relayer);
    //     l1Gateway._finalizeTransfer(recipient, amount, counterpartyIdx);
    //     // Check balances and logs to ensure transfer was finalized
    // }

    // function test_RevertIfNotRelayerFinalizesTransfer() public {
    //     address recipient = address(0x3);
    //     uint256 amount = 2 ether;
    //     uint256 counterpartyIdx = 1;

    //     vm.expectRevert("Only relayer can call this function");
    //     l1Gateway._finalizeTransfer(recipient, amount, counterpartyIdx);
    // }

    // receive() external payable {}
}
