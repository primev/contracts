pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BlockTracker is Ownable {
    event NewL1Block(uint256 indexed blockNumber, address indexed winner);

    event NewWindow(uint256 indexed window);

    uint256 public currentWindow;
    uint256 public blocksPerWindow = 64;
    uint256 public lastL1BlockNumber;
    address public lastL1BlockWinner;

    constructor(
        address _owner
    ) Ownable() {
        _transferOwnership(_owner);
    }

    function getLastL1BlockNumber() external view returns (uint256) {
        return lastL1BlockNumber;
    }

    function getLastL1BlockWinner() external view returns (address) {
        return lastL1BlockWinner;
    }

    function getCurrentWindow() external view returns (uint256) {
        return currentWindow;
    }

    function recordL1Block(
        uint256 _blockNumber,
        address _winner
    ) external onlyOwner {
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