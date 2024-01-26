// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

import {Gateway} from "./Gateway.sol";
import {IWhitelist} from "../interfaces/IWhitelist.sol";

contract SettlementGateway is Gateway{

    // Assuming deployer is 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
    // whitelist's create2 addr should be 0x5D1415C0973034d162F5FEcF19B50dA057057e29.
    // This variable is not hardcoded for testing purposes.
    address public immutable whitelistAddr;
    
    constructor(address _whitelistAddr, address _owner, address _relayer, uint256 _finalizationFee, uint256 _counterpartyFee
        ) Gateway(_owner, _relayer, _finalizationFee, _counterpartyFee) {
            whitelistAddr = _whitelistAddr;
        }

    // Burns native ether on settlement chain, 
    // there should be equiv ether on L1 which will be UNLOCKED during finalization.
    function _decrementMsgSender(uint256 _amount) internal override {
        IWhitelist(whitelistAddr).burn(msg.sender, _amount);
    }

    // Mints native ether on settlement chain, 
    // there should be equiv ether on L1 which remains LOCKED.
    function _fund(uint256 _amount, address _toFund) internal override {
        IWhitelist(whitelistAddr).mint(_toFund, _amount);
    }
}
