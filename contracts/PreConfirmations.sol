// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IProviderRegistry} from "./interfaces/IProviderRegistry.sol";
import {IUserRegistry} from "./interfaces/IUserRegistry.sol";
import {MessageHashUtils} from
    "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title PreConfCommitmentStore - A contract for managing preconfirmation commitments and bids.
 * @notice This contract allows users to make precommitments and bids and provides a mechanism for the oracle to verify and process them.
 * @dev This contract should not be used in production as it is for demonstration purposes.
 */
contract PreConfCommitmentStore is Ownable {
    using ECDSA for bytes32;

    /// @dev EIP-712 Type Hash for preconfirmation commitment
    bytes32 public constant EIP712_COMMITMENT_TYPEHASH = keccak256(
        "PreConfCommitment(string txnHash,uint64 bid,uint64 blockNumber,string bidHash,string signature)"
    );

    /// @dev EIP-712 Type Hash for preconfirmation bid
    bytes32 public constant EIP712_MESSAGE_TYPEHASH =
        keccak256("PreConfBid(string txnHash,uint64 bid,uint64 blockNumber)");

    /// @dev commitment counter
    uint256 public commitmentCount;

    /// @dev Address of the oracle
    address public oracle;

    // EIP-712 Domain Separator
    bytes32 public DOMAIN_SEPARATOR_PRECONF;

    // EIP-712 Domain Separator
    bytes32 public DOMAIN_SEPARATOR_BID;

    /// @dev Address of provider registry
    IProviderRegistry public providerRegistry;

    /// @dev Address of userRegistry
    IUserRegistry public userRegistry;

    /// @dev Commitment Hash -> Commitemnt
    /// @dev Only stores valid commitments
    mapping(bytes32 => PreConfCommitment) public commitments;

    /// @dev Mapping to keep track of used PreConfCommitments
    mapping(bytes32 => bool) public usedCommitments;

    /// @dev Mapping from address to preconfbid list
    mapping(address => PreConfBid[]) public bids;

    /// @dev Mapping from address to commitmentss list
    mapping(address => PreConfCommitment[]) public commitmentss;

    /// @dev Struct for all the information around preconfirmations commitment
    struct PreConfCommitment {
        address bidder;
        address commiter;
        uint64 bid;
        uint64 blockNumber;
        bytes32 bidHash;
        string txnHash;
        string commitmentHash;
        bytes bidSignature;
        bytes commitmentSignature;
    }

    /// @dev Struct for pre confirmation bid
    struct PreConfBid {
        uint64 bid;
        uint64 blockNumber;
        bytes32 bidHash;
        string txnHash;
        bytes bidSignature;
    }

    /// @dev Event to log successful verifications
    event SignatureVerified(
        address indexed signer,
        string txnHash,
        uint64 indexed bid,
        uint64 blockNumber
    );

    /**
     * @dev fallback to revert all the calls.
     */
    fallback() external payable {
        revert("Invalid call");
    }

    /**
     * @dev Revert if eth sent to this contract
     */
    receive() external payable {
        revert("Invalid call");
    }

    /**
     * @dev Makes sure transaction sender is oracle
     */
    modifier onlyOracle() {
        require(msg.sender == oracle, "Only the oracle can call this function");
        _;
    }

    /**
     * @dev Initializes the contract with the specified registry addresses, oracle, name, and version.
     * @param _providerRegistry The address of the provider registry.
     * @param _userRegistry The address of the user registry.
     * @param _oracle The address of the oracle.
     */
    constructor(
        address _providerRegistry,
        address _userRegistry,
        address _oracle
    )
        Ownable(msg.sender)
    {
        oracle = _oracle;
        providerRegistry = IProviderRegistry(_providerRegistry);
        userRegistry = IUserRegistry(_userRegistry);

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
    }

    /**
     * @dev Get the bids for a specific address.
     * @param adr The address for which to retrieve bids.
     * @return An array of PreConfBid structures representing the bids made by the address.
     */
    function getBidsFor(address adr)
        public
        view
        returns (PreConfBid[] memory)
    {
        return bids[adr];
    }

    /**
     * @dev Gives digest to be signed for bids
     * @param _txnHash transaction Hash.
     * @param _bid bid id.
     * @param _blockNumber block number
     * @return digest it returns a digest that can be used for signing bids
     */
    function getBidHash(
        string memory _txnHash,
        uint64 _bid,
        uint64 _blockNumber
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR_BID,
                keccak256(
                    abi.encode(
                        EIP712_MESSAGE_TYPEHASH,
                        keccak256(abi.encodePacked(_txnHash)),
                        _bid,
                        _blockNumber
                    )
                )
            )
        );
    }

    /**
     * @dev Gives digest to be signed for pre confirmation
     * @param _txnHash transaction Hash.
     * @param _bid bid id.
     * @param _blockNumber block number.
     * @param _bidHash hash of the bid.
     * @return digest it returns a digest that can be used for signing bids.
     */
    function getPreConfHash(
        string memory _txnHash,
        uint64 _bid,
        uint64 _blockNumber,
        bytes32 _bidHash,
        string memory _bidSignature
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR_PRECONF,
                keccak256(
                    abi.encode(
                        EIP712_COMMITMENT_TYPEHASH,
                        keccak256(abi.encodePacked(_txnHash)),
                        _bid,
                        _blockNumber,
                        keccak256(abi.encodePacked(bytes32ToHexString(_bidHash))),
                        keccak256(abi.encodePacked(_bidSignature))
                    )
                )
            )
        );
    }

    /**
     * @dev Retrieve a list of commitments.
     * @return An array of PreConfCommitment structures representing the commitments made.
     */
    function retreiveCommitments()
        public
        view
        returns (PreConfCommitment[] memory)
    {
        PreConfCommitment[] memory commitmentsList = new PreConfCommitment[](1);
        commitmentsList[0] = commitments[0];
        // Get keys from
        return commitmentsList;
    }

    /**
     * @dev Retrieve a commitment.
     * @return A PreConfCommitment structure representing the specified commitment.
     */
    function retreiveCommitment()
        public
        view
        returns (PreConfCommitment memory)
    {
        return commitments[0];
    }

    /**
     * @dev Internal function to verify a bid
     * @param bid bid id.
     * @param blockNumber block number.
     * @param txnHash transaction Hash.
     * @param bidSignature bid signature.
     * @return messageDigest returns the bid hash for given bid id.
     * @return recoveredAddress the address from the bid hash.
     * @return stake the stake amount of the address for bid id user.
     */
    function verifyBid(
        uint64 bid,
        uint64 blockNumber,
        string memory txnHash,
        bytes calldata bidSignature
    )
        public
        view
        returns (bytes32 messageDigest, address recoveredAddress, uint256 stake)
    {
        messageDigest = getBidHash(txnHash, bid, blockNumber);
        recoveredAddress = messageDigest.recover(bidSignature);
        stake = userRegistry.checkStake(recoveredAddress);
        require(stake > 10 * bid, "Invalid bid");
    }

    /**
     * @dev Store a commitment.
     * @param bid The bid amount.
     * @param blockNumber The block number.
     * @param txnHash The transaction hash.
     * @param commitmentHash The commitment hash.
     * @param bidSignature The signature of the bid.
     * @param commitmentSignature The signature of the commitment.
     * @return The new commitment count.
     */
    function storeCommitment(
        uint64 bid,
        uint64 blockNumber,
        string memory txnHash,
        string memory commitmentHash,
        bytes calldata bidSignature,
        bytes memory commitmentSignature
    )
        public
        returns (uint256)
    {
        // Fixing stack too deep

        (bytes32 bHash, address bidderAddress, uint256 stake) =
            verifyBid(bid, blockNumber, txnHash, bidSignature);

        // This helps in avoiding stack too deep
        {
            bytes32 preConfHash = getPreConfHash(
                txnHash, bid, blockNumber, bHash, bytesToHexString(bidSignature)
            );
            address commiterAddress = preConfHash.recover(commitmentSignature);

            require(stake > (10 * bid), "Stake too low");

            commitments[preConfHash] = PreConfCommitment(
                commiterAddress,
                bidderAddress,
                bid,
                blockNumber,
                bHash,
                txnHash,
                commitmentHash,
                bidSignature,
                commitmentSignature
            );
            commitmentCount++;
        }

        return commitmentCount;
    }

    /**
     * @dev Get a commitment by its hash.
     * @param commitmentHash The hash of the commitment.
     * @return A PreConfCommitment structure representing the commitment.
     */
    function getCommitment(bytes32 commitmentHash)
        public
        view
        returns (PreConfCommitment memory)
    {
        return commitments[commitmentHash];
    }

    /**
     * @dev Initiate a slash for a commitment.
     * @param commitmentHash The hash of the commitment to be slashed.
     */
    function initiateSlash(bytes32 commitmentHash) public onlyOracle {
        PreConfCommitment memory commitment = commitments[commitmentHash];
        require(!usedCommitments[commitmentHash], "Commitment already used");
        // Mark this commitment as used to prevent replays
        usedCommitments[commitmentHash] = true;

        providerRegistry.slash(
            commitment.bid, commitment.commiter, payable(commitment.bidder)
        );
    }

    /**
     * @dev Initiate a reward for a commitment.
     * @param commitmentHash The hash of the commitment to be rewarded.
     */
    function initateReward(bytes32 commitmentHash) public onlyOracle {
        PreConfCommitment memory commitment = commitments[commitmentHash];
        require(!usedCommitments[commitmentHash], "Commitment already used");
        // Mark this commitment as used to prevent replays
        usedCommitments[commitmentHash] = true;

        userRegistry.retrieveFunds(
            commitment.bidder, commitment.bid, payable(commitment.commiter)
        );
    }

    /**
     * @dev Updates the address of the oracle.
     * @param newOracle The new oracle address.
     */
    function updateOracle(address newOracle) external onlyOwner {
        oracle = newOracle;
    }

    /**
     * @dev Updates the address of the provider registry.
     * @param newProviderRegistry The new provider registry address.
     */
    function updateProviderRegistry(address newProviderRegistry)
        public
        onlyOwner
    {
        providerRegistry = IProviderRegistry(newProviderRegistry);
    }

    /**
     * @dev Updates the address of the user registry.
     * @param newUserRegistry The new user registry address.
     */
    function updateUserRegistry(address newUserRegistry) external onlyOwner {
        userRegistry = IUserRegistry(newUserRegistry);
    }

    function bytes32ToHexString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        bytes memory HEXCHARS = "0123456789abcdef";
        bytes memory _string = new bytes(64);
        for (uint8 i = 0; i < 32; i++) {
            _string[i * 2] = HEXCHARS[uint8(_bytes32[i] >> 4)];
            _string[1 + i * 2] = HEXCHARS[uint8(_bytes32[i] & 0x0f)];
        }
        return string(_string);
    }

    function bytesToHexString(bytes memory _bytes)
        public
        pure
        returns (string memory)
    {
        bytes memory HEXCHARS = "0123456789abcdef";
        bytes memory _string = new bytes(_bytes.length * 2);
        for (uint256 i = 0; i < _bytes.length; i++) {
            _string[i * 2] = HEXCHARS[uint8(_bytes[i] >> 4)];
            _string[1 + i * 2] = HEXCHARS[uint8(_bytes[i] & 0x0f)];
        }
        return string(_string);
    }

    // Add to your contract
    function recoverAddress(bytes32 messageDigest, bytes memory signature)
        public
        pure
        returns (address)
    {
        return messageDigest.recover(signature);
    }
}
