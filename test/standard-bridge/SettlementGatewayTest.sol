// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../../contracts/standard-bridge/SettlementGateway.sol";
import "../../contracts/interfaces/IWhitelist.sol";

contract MockWhitelist is IWhitelist {
    uint256 public mintIdx;
    address public lastMintTo;
    uint256 public lastMintAmount;

    uint256 public burnIdx;
    address public lastBurnFrom;
    uint256 public lastBurnAmount;

    function mint(address _to, uint256 _amount) external override {
        ++mintIdx;
    }

    function burn(address _from, uint256 _amount) external override {
        ++burnIdx;
        lastBurnFrom = _from;
        lastBurnAmount = _amount;
    }
}

contract SettlementGatewayTest is Test {

    SettlementGateway settlementGateway;
    MockWhitelist mockWhitelist;

    address owner;
    address relayer;
    address bridgeUser;
    uint256 finalizationFee;
    uint256 counterpartyFee;

    function setUp() public {
        owner = address(this); // Original contract deployer as owner
        relayer = address(0x78);
        bridgeUser = address(0x101);
        finalizationFee = 0.05 ether;
        counterpartyFee = 0.1 ether;
        mockWhitelist = new MockWhitelist();
        settlementGateway = new SettlementGateway(address(mockWhitelist), owner, relayer, finalizationFee, counterpartyFee);
    }

    function test_ConstructorSetsVariablesCorrectly() public {
        // Test if the constructor correctly initializes variables
        assertEq(settlementGateway.owner(), owner);
        assertEq(settlementGateway.relayer(), relayer);
        assertEq(settlementGateway.finalizationFee(), finalizationFee);
        assertEq(settlementGateway.counterpartyFee(), counterpartyFee);
        assertEq(settlementGateway.whitelistAddr(), address(mockWhitelist));
    }

    // Expected event signature emitted in initiateTransfer()
    event TransferInitiated(
        address indexed sender, address indexed recipient, uint256 amount, uint256 transferIdx);

    function test_InitiateTransfer() public {
        vm.deal(bridgeUser, 100 ether);
        uint256 amount = 7 ether;

        // Initial assertions
        assertEq(address(bridgeUser).balance, 100 ether);
        assertEq(settlementGateway.transferIdx(), 0);

        // Set up expectation for event
        vm.expectEmit(true, true, true, true);
        emit TransferInitiated(bridgeUser, bridgeUser, amount, 1);

        // Call function as bridgeUser
        vm.prank(bridgeUser);
        uint256 returnedIdx = settlementGateway.initiateTransfer{value: amount}(bridgeUser, amount);

        // Assertions after call
        assertEq(mockWhitelist.burnIdx(), 1);
        assertEq(mockWhitelist.lastBurnFrom(), bridgeUser);
        assertEq(mockWhitelist.lastBurnAmount(), amount);

        assertEq(settlementGateway.transferIdx(), 1);
        assertEq(returnedIdx, 1); 
    }

    function TestAmountTooSmallForCounterpartyFee() public {
        vm.deal(bridgeUser, 100 ether);
        vm.deal(address(settlementGateway), 1 ether);
        assertEq(address(bridgeUser).balance, 100 ether);
        vm.expectRevert("Amount must cover counterpartys finalization fee");
        vm.prank(bridgeUser);
        settlementGateway.initiateTransfer{value: 0.04 ether}(bridgeUser, 0.04 ether);
    }

    event TransferFinalized(
        address indexed recipient, uint256 amount, uint256 counterpartyIdx);
    
    function test_FinalizeTransfer() public {
        // These values are trusted from relayer
        uint256 amount = 2 ether;
        uint256 counterpartyIdx = 8;

        // Fund gateway and relayer
        vm.deal(address(settlementGateway), 3 ether);
        vm.deal(relayer, 3 ether);

        // Initial assertions
        assertEq(address(settlementGateway).balance, 3 ether);
        assertEq(relayer.balance, 3 ether);
        assertEq(bridgeUser.balance, 0 ether);
        assertEq(settlementGateway.transferIdx(), 0);

        // Set up expectation for event
        vm.expectEmit(true, true, true, true);
        emit TransferFinalized(bridgeUser, amount, counterpartyIdx);

        // Call function as relayer
        vm.prank(relayer);
        settlementGateway.finalizeTransfer(bridgeUser, amount, counterpartyIdx);

        assertEq(mockWhitelist.mintIdx(), 2);
        assertEq(settlementGateway.transferIdx(), 0);
    }

    function test_OnlyRelayerCanCallFinalizeTransfer() public {
        vm.expectRevert("Only relayer can call this function");
        vm.prank(bridgeUser);
        settlementGateway.finalizeTransfer(bridgeUser, 1 ether, 1);
    }

    function test_AmountTooSmallForFinalizationFee() public {
        vm.deal(address(settlementGateway), 1 ether);
        vm.deal(relayer, 1 ether);
        vm.expectRevert("Amount must cover finalization fee");
        vm.prank(relayer);
        settlementGateway.finalizeTransfer(bridgeUser, 0.04 ether, 1);
    }
}
