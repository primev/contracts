// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./IProviderRegistry.sol";
import "./IUserRegistry.sol";

// L2 should have a mechanism to reach down to the L1 time/block


contract PreConfCommitmentStore {
    struct PreConfCommitment {
        string txnHash;
        uint64 bid;
        uint64 blockNumber;
        string bidHash;
        string bidSignature;

        string commitmentHash;
        bytes commitmentSignature;


        address bidder;
        address commiter;

    }

    struct PreConfBid {
        string txnHash;
        uint64 bid;
        uint64 blockNumber;

        bytes32 bidHash;
        bytes bidSignature;
    }


    // Address of the oracle
    address public oracle;

    // EIP-712 Type Hash for the message
    bytes32 public constant EIP712_COMMITMENT_TYPEHASH = keccak256(
        "PreConfCommitment(string txnHash,uint64 bid,uint64 blockNumber,string bidHash,string signature)"
    );

    // EIP-712 Domain Separator
    bytes32 public DOMAIN_SEPARATOR_PRECONF;

    // EIP-712 Domain Separator
    bytes32 public DOMAIN_SEPARATOR_BID;

    // EIP-712 Type Hash for the message
    // PreConfBid(string txnHash, uint64 bid, uint64 blockNumber)
    bytes32 public constant EIP712_MESSAGE_TYPEHASH = keccak256("PreConfBid(string txnHash,uint64 bid,uint64 blockNumber)");

    // Event to log successful verifications
    event SignatureVerified(address indexed signer, string txnHash, uint64 bid, uint64 blockNumber);

    uint256 public commitmentCount;

    IProviderRegistry public providerRegistry;
    IUserRegistry public userRegistry;

    constructor(address _providerRegistry, address _userRegistry, address _oracle) {
        // EIP-712 domain separator
        DOMAIN_SEPARATOR_PRECONF = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version)"),
                keccak256("PreConfCommitment"),
                keccak256("1")
            )
        );
        // EIP-712 domain separator
        DOMAIN_SEPARATOR_BID = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version)"),
                keccak256("PreConfBid"),
                keccak256("1")
            )
        );

        oracle = _oracle;
        commitmentCount = 0;
        providerRegistry = IProviderRegistry(_providerRegistry);
        userRegistry = IUserRegistry(_userRegistry);
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "Only the oracle can call this function");
        _;
    }

    // Commitment Hash -> Commitemnt
    // Only stores valid commitments
    mapping(bytes32 => PreConfCommitment) public commitments;

    // Mapping to keep track of used PreConfCommitments
    mapping(bytes32 => bool) public usedCommitments;

    mapping(address => PreConfBid[]) public bids;
    mapping(address => PreConfCommitment[]) public commitmentss;

    function getBidsFor(address adr) public view returns (PreConfBid[] memory) {
        return bids[adr];
    }

    // TODO(@ckartik): Update to not be view
    function getBidHash(string memory _txnHash, uint64 _bid, uint64 _blockNumber) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR_BID,
                keccak256(abi.encode(
                    EIP712_MESSAGE_TYPEHASH, 
                    keccak256(abi.encodePacked(_txnHash)),
                     _bid,
                      _blockNumber))
            )
        );
    }

    function getPreConfHash(string memory _txnHash, uint64 _bid, uint64 _blockNumber, bytes32 _bidHash, string memory _bidSignature) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR_PRECONF,
                keccak256(abi.encode(
                    EIP712_COMMITMENT_TYPEHASH, 
                    keccak256(abi.encodePacked(_txnHash)),
                     _bid,
                      _blockNumber,
                      keccak256(abi.encodePacked(bytes32ToHexString(_bidHash))),
                      keccak256(abi.encodePacked(_bidSignature))
                      ))
            )
        );
    }

    // Add to your contract
    function recoverAddress(bytes32 messageDigest, bytes memory signature) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        
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
    
    function verifyBid(
        string memory txnHash,
        uint64 bid,
        uint64 blockNumber,
        bytes memory bidSignature
    ) public view returns (bool, bytes32, address) {
        bytes32 messageDigest = getBidHash(txnHash, bid, blockNumber);
        address bidderAddress = recoverAddress(messageDigest, bidSignature);
        assert(bidderAddress != address(0));
        uint256 stake = userRegistry.checkStake(bidderAddress);
        // TODO(@ckartik): Do in a safe context
        console.log("Stake: %s", stake);
        console.log("Bid: %s", 10*bid);
        assert(stake > 10*bid);
        return (true, messageDigest, bidderAddress);
    }
    
    function bytes32ToHexString(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory HEXCHARS = "0123456789abcdef";
        bytes memory _string = new bytes(64);
        for (uint8 i = 0; i < 32; i++) {
            _string[i*2] = HEXCHARS[uint8(_bytes32[i] >> 4)];
            _string[1+i*2] = HEXCHARS[uint8(_bytes32[i] & 0x0f)];
        }
        return string(_string);
    }
    
    function bytesToHexString(bytes memory _bytes) public pure returns (string memory) {
        bytes memory HEXCHARS = "0123456789abcdef";
        bytes memory _string = new bytes(_bytes.length * 2);
        for (uint i = 0; i < _bytes.length; i++) {
            _string[i * 2] = HEXCHARS[uint8(_bytes[i] >> 4)];
            _string[1 + i * 2] = HEXCHARS[uint8(_bytes[i] & 0x0f)];
        }
        return string(_string);
    }

    // Updated function signature to include bidSignature
    // TODO(@ckartik): Verify the signature before storing, and store in address map
    function storeCommitment(
        string memory txnHash,
        uint64 bid,
        uint64 blockNumber,
        string memory bidHash,
        bytes memory bidSignature,
        string memory commitmentHash,
        bytes memory commitmentSignature
    ) public returns (uint256) {
        // uint256 commitmentCount = uint256(keccak256(abi.encodePacked(txnHash, bid, blockNumber, bidHash, bidSignature, commitmentSignature)));
        console.log("Recieved commitment");
        console.log("txnHash: %s", txnHash);
        console.log("bid: %s", bid);
        console.log("blockNumber: %s", blockNumber);
        console.log("bidHash: %s", bidHash);
        // console.log("bidSignature: %s", bidSignature);
        // console.logBytes("commitmentSignature: %s", commitmentSignature);
        
        // Verify the bid
        (bool bidValidity, bytes32 bHash, address bidderAddress) = verifyBid(txnHash, bid, blockNumber, bytes(bidSignature));
        assert(bidValidity);
        bytes32 preConfHash = getPreConfHash(txnHash, bid, blockNumber, bHash, bytesToHexString(bidSignature));
        console.logBytes32(preConfHash);
        console.log("commitmentHash: %s", commitmentHash);
        address commiterAddress = recoverAddress(preConfHash, commitmentSignature);
        console.log("Commiter address: %s", commiterAddress);

        uint256 stake = providerRegistry.checkStake(commiterAddress);

        // This is curently abritrary.
        assert(stake > 10*bid);
        commitments[preConfHash] = PreConfCommitment(txnHash, bid, blockNumber, bytes32ToHexString(bHash), string(bidSignature), commitmentHash, commitmentSignature, bidderAddress, commiterAddress);
        commitmentCount++;

        return commitmentCount;
    }

    function getCommitment(bytes32 commitemntHash) public view returns (PreConfCommitment memory) {
        return commitments[commitemntHash];
    }

    function initiateSlash(bytes32 commitmentHash) public onlyOracle {
        PreConfCommitment memory commitment = commitments[commitmentHash];

        require(!usedCommitments[commitmentHash], "Commitment already used");
        providerRegistry.Slash( commitment.bid, commitment.commiter, payable(commitment.bidder));

        // Mark this commitment as used to prevent replays
        usedCommitments[commitmentHash] = true;
    }

    function initateReward(bytes32 commitmentHash) public onlyOracle {
        PreConfCommitment memory commitment = commitments[commitmentHash];

        require(!usedCommitments[commitmentHash], "Commitment already used");
        userRegistry.RetrieveFunds( commitment.bidder, commitmentHash, commitment.bid, payable(commitment.commiter));

        // Mark this commitment as used to prevent replays
        usedCommitments[commitmentHash] = true;
    }
}
