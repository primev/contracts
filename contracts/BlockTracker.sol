pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BlockTracker
 * @dev A contract that tracks Ethereum blocks and their winners.
 */
contract BlockTracker is Ownable {
    /// @dev Event emitted when a new L1 block is tracked.
    event NewL1Block(uint256 indexed blockNumber, address indexed winner);

    /// @dev Event emitted when a new window is created.
    event NewWindow(uint256 indexed window);

    uint256 public currentWindow;
    uint256 public blocksPerWindow = 64;
    uint256 public lastL1BlockNumber;
    address public lastL1BlockWinner;

    /**
     * @dev Initializes the BlockTracker contract with the specified owner.
     * @param _owner The address of the contract owner.
     */
    constructor(address _owner) Ownable() {
        _transferOwnership(_owner);
    }

    /**
     * @dev Returns the number of the last L1 block recorded.
     * @return The number of the last L1 block recorded.
     */
    function getLastL1BlockNumber() external view returns (uint256) {
        return lastL1BlockNumber;
    }

    /**
     * @dev Returns the winner of the last L1 block recorded.
     * @return The address of the winner of the last L1 block recorded.
     */
    function getLastL1BlockWinner() external view returns (address) {
        return lastL1BlockWinner;
    }

    /**
     * @dev Returns the current window number.
     * @return The current window number.
     */
    function getCurrentWindow() external view returns (uint256) {
        return currentWindow;
    }

    /**
     * @dev Records a new L1 block and its winner.
     * @param _blockNumber The number of the new L1 block.
     * @param _winner The address of the winner of the new L1 block.
     */
    function recordL1Block(uint256 _blockNumber, address _winner) external onlyOwner {
        lastL1BlockNumber = _blockNumber;
        lastL1BlockWinner = _winner;
        emit NewL1Block(_blockNumber, _winner);
        uint256 newWindow = (_blockNumber - 1) / blocksPerWindow + 1;
        if (newWindow > currentWindow) {
            // We've entered a new window
            currentWindow = newWindow;
            emit NewWindow(currentWindow);
        }
    }

    /**
     * @dev Fallback function to revert all calls, ensuring no unintended interactions.
     */
    fallback() external payable {
        revert("Invalid call");
    }

    /**
     * @dev Receive function is disabled for this contract to prevent unintended interactions.
     * Should be removed from here in case the registerAndStake function becomes more complex
     */
    receive() external payable {
        revert("Invalid call");
    }
}