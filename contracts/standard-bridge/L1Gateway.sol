// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Gateway.sol";

// TODO: Make ownable upgradeable
contract L1Gateway is Gateway, Ownable {

    constructor(address _relayer, uint256 _finalizationFee, uint256 _counterpartyFee
        ) Gateway(_relayer, _finalizationFee, _counterpartyFee) Ownable() {}

    function _decrementMsgSender(uint256 _amount) internal override {
        require(msg.value == _amount, "Incorrect Ether value sent");
        // Ether is automatically escrowed in the contract balance
    }

    function _fund(uint256 _amount, address _toFund) internal override {
        require(address(this).balance >= _amount, "Insufficient contract balance");
        payable(_toFund).transfer(_amount);
    }

    // TODO: test functionality
    receive() external payable {}
}

