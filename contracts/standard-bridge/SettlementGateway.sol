// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Gateway.sol";

// TODO: Make ownable upgradeable
contract SettlementGateway is Gateway, Ownable {
    
    constructor(address _relayer, uint256 _finalizationFee, uint256 _counterpartyFee
        ) Gateway(_relayer, _finalizationFee, _counterpartyFee) Ownable() {}

    function _decrementMsgSender(uint256 _amount) internal override {
        // TODO: BURN, there should be equiv ether locked on L1
    }

    function _fund(uint256 _amount, address _toFund) internal override {
        // TODO: MINT, there should be equiv ether locked on L1
    }
}
