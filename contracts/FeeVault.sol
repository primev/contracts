// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

// See hyperlane token router: https://github.com/primevprotocol/hyperlane-monorepo/blob/1c8cdc9e57389024274242d28e032a2de535c2c7/solidity/contracts/token/libs/TokenRouter.sol
interface ITokenRouter {
    function transferRemote(uint32 _destination, bytes32 _recipient, uint256 _amountOrId) external payable returns (bytes32);
}

// TODO: Make this it's own file, hyperlane should ref it too
interface IWhitelist {
    function mint(address _mintTo, uint256 _amount) external;
    function burn(address _burnFrom, uint256 _amount) external;
}

contract FeeVault is Ownable {
    address public immutable treasury;
    uint256 public immutable destinationChainId;
    ITokenRouter private tokenRouter;

    constructor(address _treasury, address _tokenRouterAddr, uint256 _destinationChainId) {
        require(_treasury != address(0), "Treasury address cannot be zero");
        treasury = _treasury;
        require(_tokenRouterAddr != address(0), "TokenRouter address cannot be zero");
        tokenRouter = ITokenRouter(_tokenRouterAddr);
        require(_destinationChainId != 0, "Destination chain ID cannot be zero");
        destinationChainId = _destinationChainId;

        // Note the fee vault contract needs to burn funds accumulated from "operational
        // accounts" funded on genesis, who submit chain initialization transactions.
        // This pre-setup ether does not have corresponding liquidity on the L1 hyperlane contract.
        //
        // TODO: Address following concerns: 
        // - Confirm idea works
        // - Confirm we can avoid accounting logic altogether?
        // - Possibly burn account balances of all hardcoded operational accounts in this constructor? 
        // - What about burning signer balances?
        // - Will most likely need ether buffer deposited into L1 contract equal to cumulative fees needed for sidechain setup
        uint256 initialBalance = address(this).balance;
        if (initialBalance > 0) {
            whitelist.burn(address(this), initialBalance);
            emit AmountBurned(initialBalance);
        }
    }

    function transferToL1() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to transfer");

        // Convert the treasury address to bytes32 for transferRemote call
        // TODO: Confirm how this is done in hyperlane repo
        bytes32 recipient = bytes32(uint256(uint160(treasury)));

        tokenRouter.transferRemote{value: balance}(destinationChainId, recipient, balance);
    }

    // Allows contract to receive ether accumulated before deployment
    receive() external payable {}
}
