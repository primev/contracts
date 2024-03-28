// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IBlockTracker interface for BlockTracker contract
interface IBlockTracker {
    /// @notice Retrieves the number of the last L1 block tracked.
    /// @return The block number of the last tracked L1 block.
    function getLastL1BlockNumber() external view returns (uint256);

    /// @notice Retrieves the winner of the last L1 block tracked.
    /// @return The address of the winner of the last tracked L1 block.
    function getLastL1BlockWinner() external view returns (address);

    /// @notice Retrieves the current window.
    /// @return The current window number.
    function getCurrentWindow() external view returns (uint256);

    /// @notice Retrieves the number of blocks per window.
    /// @return The number of blocks per window.
    function getBlocksPerWindow() external view returns (uint256);

    /// @notice Sets the number of blocks per window.
    /// @param _blocksPerWindow The new number of blocks per window.
    /// @dev Only callable by the owner.
    function setBlocksPerWindow(uint256 _blocksPerWindow) external;

    /// @notice Retrieves the winner of a specific L1 block.
    /// @param _blockNumber The block number of the L1 block.
    /// @return The address of the winner of the L1 block.
    function getBlockWinner(uint256 _blockNumber) external view returns (address);
    
    /// @notice Records a new L1 block with its winner.
    /// @param _blockNumber The block number of the new L1 block.
    /// @param _winner The address of the winner of the new L1 block.
    function recordL1Block(uint256 _blockNumber, address _winner) external;

    /// @notice Emitted when a new L1 block is recorded.
    /// @param blockNumber The block number of the new L1 block.
    /// @param winner The address of the winner of the new L1 block.
    event NewL1Block(uint256 indexed blockNumber, address indexed winner);

    /// @notice Emitted when entering a new window.
    /// @param window The new window number.
    event NewWindow(uint256 indexed window);
}
