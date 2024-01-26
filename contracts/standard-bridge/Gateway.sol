// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Gateway contract for standard bridge. 
 */
abstract contract Gateway is Ownable {   
    
    // @dev index for tracking transfers.
    // Also total number of transfers initiated from this gateway.
    uint256 public transferIdx;

    // @dev Address of relayer account. 
    address public immutable relayer;

    // @dev Flat fee paid to relayer on destination chain upon transfer finalization.
    // This must be greater than what relayer will pay per tx.
    uint256 public immutable finalizationFee;

    // The counterparty's finalization fee, included for UX purposes
    uint256 public immutable counterpartyFee;

    constructor(address _owner, address _relayer, 
        uint256 _finalizationFee, uint256 _counterpartyFee) Ownable() {
        relayer = _relayer;
        finalizationFee = _finalizationFee;
        counterpartyFee = _counterpartyFee;
        _transferOwnership(_owner);
    }

    modifier onlyRelayer() {
        require(msg.sender == relayer, "Only relayer can call this function");
        _;
    }

    function initiateTransfer(address _recipient, uint256 _amount
    ) external payable returns (uint256 returnIdx) {
        require(_amount >= counterpartyFee, "Amount must cover counterpartys finalization fee");
        ++transferIdx;
        _decrementMsgSender(_amount);
        emit TransferInitiated(msg.sender, _recipient, _amount, transferIdx);
        return transferIdx;
    }
    // @dev where _decrementMsgSender is implemented by inheriting contract.
    function _decrementMsgSender(uint256 _amount) internal virtual;

    function _finalizeTransfer(address _recipient, uint256 _amount, uint256 _counterpartyIdx
    ) external onlyRelayer {
        require(_amount >= finalizationFee, "Amount must cover finalization fee");
        uint256 amountAfterFee = _amount - finalizationFee;
        _fund(amountAfterFee, _recipient);
        _fund(finalizationFee, relayer);
        emit TransferFinalized(_recipient, _amount, _counterpartyIdx);
    }
    // @dev where _fund is implemented by inheriting contract.
    function _fund(uint256 _amount, address _toFund) internal virtual;

    /**
     * @dev Emitted when a cross chain transfer is initiated.
     * @param sender Address initiating the transfer. Indexed for efficient filtering.
     * @param recipient Address receiving the tokens. Indexed for efficient filtering.
     * @param amount Ether being transferred.
     * @param transferIdx Current index of this gateway.
     */
    event TransferInitiated(
        address indexed sender, address indexed recipient, uint256 amount, uint256 transferIdx);

    /**
     * @dev Emitted when a transfer is finalized.
     * @param recipient Address receiving the tokens. Indexed for efficient filtering.
     * @param amount Ether being transferred.
     * @param counterpartyIdx Index of counterpary gateway when transfer was initiated.
     */
    event TransferFinalized(
        address indexed recipient, uint256 amount, uint256 counterpartyIdx);
}
