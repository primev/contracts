// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

contract PreConfCommitmentStore {
    struct PreConfCommitment {
        string txnHash;
        uint64 bid;
        uint64 blockNumber;
        string bidHash;
        string bidSignature;

        string commitmentHash;
        string commitmentSignature;
    }

    struct PreConfBid {
        string txnHash;
        uint64 bid;
        uint64 blockNumber;

        string bidHash;
        string bidSignature;
    }

    // EIP-712 Domain Separator
    bytes32 public DOMAIN_SEPARATOR;

    // EIP-712 Type Hash for the message
    // PreConfBid(string txnHash, uint64 bid, uint64 blockNumber)
    bytes32 public constant EIP712_MESSAGE_TYPEHASH = keccak256("PreConfBid(string txnHash,uint64 bid,uint64 blockNumber)");

    // Event to log successful verifications
    event SignatureVerified(address indexed signer, string txnHash, uint64 bid, uint64 blockNumber);

    uint256 public commitmentCount;
    constructor() {
        // EIP-712 domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version)"),
                keccak256("PreConfBid"),
                keccak256("1")
            )
        );
        commitmentCount = 0;
    }
    mapping(uint256 => PreConfCommitment) public commitments;

    mapping(address => PreConfBid[]) public bids;
    mapping(address => PreConfCommitment[]) public commitmentss;

    function getDomainSeperator() public view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }

    function getMessageTypeHash() public view returns (bytes32) {
        return EIP712_MESSAGE_TYPEHASH;
    }
    function typedDataHash() public view returns (bytes memory) {
        return abi.encode(EIP712_MESSAGE_TYPEHASH, keccak256("0xkartik"), uint64(2), uint64(2));
    }

    // TODO(@ckartik): Update to not be view
    function hashMessage(string memory _txnHash, uint64 _bid, uint64 _blockNumber) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    EIP712_MESSAGE_TYPEHASH, 
                    keccak256(abi.encodePacked(_txnHash)),
                     _bid,
                      _blockNumber))
            )
        );
    }

    

    // Add to your contract
    function recoverAddress(string memory _txnHash, uint64 _bid, uint64 _blockNumber, bytes memory signature) public view returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        bytes32 messageDigest = hashMessage(_txnHash, _bid, _blockNumber);
        // Check the signature length
        if (signature.length != 65) {
            return address(0);
        }

        // Divide the signature into r, s, and v variables with inline assembly.
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of the signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            // EIP-2 still allows for ecrecover precompile to return `0` on an invalid signature,
            // even if a regular contract would revert.
            return ecrecover(messageDigest, v, r, s);
        }
    }


    // Get list of commitments
    function retreiveCommitments() public view returns (PreConfCommitment[] memory) {
        PreConfCommitment[] memory commitmentsList = new PreConfCommitment[](1);
        commitmentsList[0] = commitments[0];
        // Get keys from
        return commitmentsList;
    }

    function retreiveCommitment() public view returns (PreConfCommitment memory) {
        return commitments[0];
    }

    // Updated function signature to include bidSignature
    // TODO(@ckartik): Verify the signature before storing, and store in address map
    function storeCommitment(
        string memory txnHash,
        uint64 bid,
        uint64 blockNumber,
        string memory bidHash,
        string memory bidSignature,
        string memory commitmentHash,
        string memory commitmentSignature
    ) public returns (uint256) {
        // uint256 commitmentCount = uint256(keccak256(abi.encodePacked(txnHash, bid, blockNumber, bidHash, bidSignature, commitmentSignature)));
        console.log("Recieved commitment");
        console.log("txnHash: %s", txnHash);
        console.log("bid: %s", bid);
        console.log("blockNumber: %s", blockNumber);
        console.log("bidHash: %s", bidHash);
        console.log("bidSignature: %s", bidSignature);
        console.log("commitmentSignature: %s", commitmentSignature);
        
        commitments[commitmentCount] = PreConfCommitment(txnHash, bid, blockNumber, bidHash, bidSignature, commitmentHash, commitmentSignature);
        commitmentCount++;
        return commitmentCount;
    }

    function getCommitment(uint256 id) public view returns (PreConfCommitment memory) {
        return commitments[id];
    }
}
