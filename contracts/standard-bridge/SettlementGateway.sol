// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Gateway.sol";

import {IWhitelist} from "../interfaces/IWhitelist.sol";

// TODO: Make ownable upgradeable
contract SettlementGateway is Gateway, Ownable {

    // This address assumes deployer is 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
    address private constant WHITELIST_ADDR =
        address(0x5D1415C0973034d162F5FEcF19B50dA057057e29);
    
    constructor(address _relayer, uint256 _finalizationFee, uint256 _counterpartyFee
        ) Gateway(_relayer, _finalizationFee, _counterpartyFee) Ownable() {}

    // Burns native ether on settlement chain, 
    // there should be equiv ether on L1 which will be UNLOCKED during finalization.
    function _decrementMsgSender(uint256 _amount) internal override {
        IWhitelist(WHITELIST_ADDR).burn(msg.sender, _amount);
    }

    // Mints native ether on settlement chain, 
    // there should be equiv ether on L1 which remains LOCKED.
    function _fund(uint256 _amount, address _toFund) internal override {
        IWhitelist(WHITELIST_ADDR).mint(_toFund, _amount);
    }
}
