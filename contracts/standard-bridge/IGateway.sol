// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

/**
 * @dev Gateway contract for standard bridge. 
 */
interface IGateway {
    /**
     * @dev Emitted when a cross chain transfer is initiated.
     * @param sender Address initiating the transfer. Indexed for efficient filtering.
     * @param destination Address on counterparty chain being funded. Indexed for efficient filtering.
     * @param amount Ether being transferred.
     * @param idx Index to correlate events across the transfer process.
     */
    event TransferInitiated(address indexed sender, address indexed destination, uint256 amount, uint256 idx);

    /**
     * @dev Emitted when a transfer is finalized.
     * @param recipient Address receiving the tokens. Indexed for efficient filtering.
     * @param amount Ether being transferred.
     * @param idx Index to correlate events across the transfer process.
     */
    event TransferFinalized(address indexed recipient, uint256 amount, uint256 idx);
}
