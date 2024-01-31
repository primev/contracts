// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/Oracle.sol";
import "../contracts/PreConfirmations.sol";
import "../contracts/interfaces/IPreConfirmations.sol";
import "../contracts/ProviderRegistry.sol";
import "../contracts/BidderRegistry.sol";

contract OracleTest is Test {
    address internal owner;
    using ECDSA for bytes32;
    Oracle internal oracle;
    PreConfCommitmentStore internal preConfCommitmentStore;
    uint16 internal feePercent;
    uint256 internal minStake;
    address internal feeRecipient;
    ProviderRegistry internal providerRegistry;
    uint256 testNumber;
    uint64 testNumber2;
    BidderRegistry internal bidderRegistry;


    // Events to match against
    event BlockDataRequested(uint256 blockNumber);
    event BlockDataReceived(string[] txnList, uint256 blockNumber, string blockBuilderName);
    event CommitmentProcessed(bytes32 commitmentHash, bool isSlash);
    event FundsRetrieved(bytes32 indexed commitmentDigest, uint256 amount);

    function setUp() public {
        testNumber = 2;
        testNumber2 = 2;

        feePercent = 10;
        minStake = 1e18 wei;
        feeRecipient = vm.addr(9);

        providerRegistry = new ProviderRegistry(
            minStake,
            feeRecipient,
            feePercent,
            address(this)
        );
        bidderRegistry = new BidderRegistry(minStake, feeRecipient, feePercent, address(this));
        preConfCommitmentStore = new PreConfCommitmentStore(
            address(providerRegistry), // Provider Registry
            address(bidderRegistry), // User Registry
            feeRecipient, // Oracle
            address(this) // Owner
        );

        address ownerInstance = 0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3;
        vm.deal(ownerInstance, 5 ether);
        vm.startPrank(ownerInstance);
        bidderRegistry.prepay{value: 2 ether}();
        
        oracle = new Oracle(address(preConfCommitmentStore), 2, ownerInstance);
        oracle.addBuilderAddress("mev builder", ownerInstance);
        vm.stopPrank();

        preConfCommitmentStore.updateOracle(address(oracle));
        bidderRegistry.setPreconfirmationsContract(address(preConfCommitmentStore));
        providerRegistry.setPreconfirmationsContract(address(preConfCommitmentStore));

    }

    function test_MultipleBlockBuildersRegistred() public {
        vm.startPrank(0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3);
        (address builder1,) = makeAddrAndKey("k builder");
        (address builder2,) = makeAddrAndKey("primev builder");
        (address builder3,) = makeAddrAndKey("titan builder");
        (address builder4,) = makeAddrAndKey("zk builder");


        oracle.addBuilderAddress("k builder", builder1);
        oracle.addBuilderAddress("primev builder", builder2);
        oracle.addBuilderAddress("titan builder", builder3);
        oracle.addBuilderAddress("zk builder", builder4);

        assertEq(oracle.blockBuilderNameToAddress("k builder"), builder1);
        assertEq(oracle.blockBuilderNameToAddress("primev builder"), builder2);
        assertEq(oracle.blockBuilderNameToAddress("titan builder"), builder3);
        assertEq(oracle.blockBuilderNameToAddress("zk builder"), builder4);
    }

    function test_builderUnidentified() public {
        vm.startPrank(0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3);
        // Unregistered Builder
        (address bidder, uint256 bidderPk) = makeAddrAndKey("k builder");
        (address provider, uint256 providerPk) = makeAddrAndKey("primev builder");

        (address builder3,) = makeAddrAndKey("titan builder");
        (address builder4,) = makeAddrAndKey("zk builder");

        uint64 blockNumber = 2;
        uint64 bid = 2;

        oracle.addBuilderAddress("titan builder", builder3);
        oracle.addBuilderAddress("zk builder", builder4);

        assertEq(oracle.blockBuilderNameToAddress("titan builder"), builder3);
        assertEq(oracle.blockBuilderNameToAddress("zk builder"), builder4);
        vm.stopPrank();

        vm.deal(bidder, 1000 ether);
        vm.deal(provider, 1000 ether);

        vm.startPrank(bidder);
        bidderRegistry.prepay{value: 250 ether }();
        vm.stopPrank();

        vm.startPrank(provider);
        providerRegistry.registerAndStake{value: 250 ether}();
        vm.stopPrank();

        bytes32 commitmentIndex = constructAndStoreCommitment(bid, blockNumber, "0xkartik", bidderPk, providerPk);

        string[] memory txnList = new string[](1);
        txnList[0] = string(abi.encodePacked(keccak256("0xkartik")));
        vm.startPrank(0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3);
        oracle.processBuilderCommitmentForBlockNumber(commitmentIndex, blockNumber, "k builder", false);
        vm.stopPrank();
        assertEq(bidderRegistry.getProviderAmount(provider), 0);
        assertEq(providerRegistry.checkStake(provider), 250 ether);
    }

    function test_process_commitment_payment_payout() public {
        string memory txn = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d08";
        uint64 blockNumber = 200;
        uint64 bid = 2;
        string memory blockBuilderName = "kartik builder";
        (address bidder, uint256 bidderPk) = makeAddrAndKey("alice");
        (address provider, uint256 providerPk) = makeAddrAndKey("kartik");

        vm.deal(bidder, 200000 ether);
        vm.startPrank(bidder);
        bidderRegistry.prepay{value: 250 ether }();
        vm.stopPrank();

        vm.deal(provider, 200000 ether);
        vm.startPrank(provider);
        providerRegistry.registerAndStake{value: 250 ether}();
        vm.stopPrank();

        bytes32 index = constructAndStoreCommitment(bid, blockNumber, txn, bidderPk, providerPk);

        vm.startPrank(address(0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3));
        oracle.addBuilderAddress(blockBuilderName, provider);

        oracle.processBuilderCommitmentForBlockNumber(index, blockNumber, blockBuilderName, false);
        vm.stopPrank();
        assertEq(bidderRegistry.getProviderAmount(provider), bid);

    }


    function test_process_commitment_slash() public {
        string memory txn = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d08";
        uint64 blockNumber = 200;
        uint64 bid = 2;
        string memory blockBuilderName = "kartik builder";
        (address bidder, uint256 bidderPk) = makeAddrAndKey("alice");
        (address provider, uint256 providerPk) = makeAddrAndKey("kartik");

        vm.deal(bidder, 200000 ether);
        vm.startPrank(bidder);
        bidderRegistry.prepay{value: 250 ether }();
        vm.stopPrank();

        vm.deal(provider, 200000 ether);
        vm.startPrank(provider);
        providerRegistry.registerAndStake{value: 250 ether}();
        vm.stopPrank();

        bytes32 index = constructAndStoreCommitment(bid, blockNumber, txn, bidderPk, providerPk);

        vm.startPrank(address(0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3));
        oracle.addBuilderAddress(blockBuilderName, provider);

        vm.expectEmit(true, false, false, true);
        emit CommitmentProcessed(index, true);
        oracle.processBuilderCommitmentForBlockNumber(index, blockNumber, blockBuilderName, true);
        vm.stopPrank();
        assertEq(providerRegistry.checkStake(provider) + bid, 250 ether);
    }


    function test_process_commitment_slash_and_reward() public {
        string memory txn1 = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d08";
        string memory txn2 = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d09";
        uint64 blockNumber = 201;
        uint64 bid = 5;
        string memory blockBuilderName = "kartik builder";
        (address bidder, uint256 bidderPk) = makeAddrAndKey("alice");
        (address provider, uint256 providerPk) = makeAddrAndKey("kartik");

        vm.deal(bidder, 200000 ether);
        vm.startPrank(bidder);
        bidderRegistry.prepay{value: 250 ether }();
        vm.stopPrank();

        vm.deal(provider, 200000 ether);
        vm.startPrank(provider);
        providerRegistry.registerAndStake{value: 250 ether}();
        vm.stopPrank();

        bytes32 index1 = constructAndStoreCommitment(bid, blockNumber, txn1, bidderPk, providerPk);
        bytes32 index2 = constructAndStoreCommitment(bid, blockNumber, txn2, bidderPk, providerPk);

        vm.startPrank(address(0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3));
        oracle.addBuilderAddress(blockBuilderName, provider);

        vm.expectEmit(true, false, false, true);
        emit CommitmentProcessed(index1, true);
        oracle.processBuilderCommitmentForBlockNumber(index1, blockNumber, blockBuilderName, true);

        vm.expectEmit(true, false, false, true);
        emit CommitmentProcessed(index2, false);
        oracle.processBuilderCommitmentForBlockNumber(index2, blockNumber, blockBuilderName, false);
        vm.stopPrank();
        assertEq(providerRegistry.checkStake(provider), 250 ether - bid);
        assertEq(bidderRegistry.getProviderAmount(provider), bid);
    }


    function test_process_commitment_slash_multiple() public {
        string memory txn1 = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d08";
        string memory txn2 = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d09";
        string memory txn3 = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d10";
        string memory txn4 = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d11";
        uint64 blockNumber = 201;
        uint64 bid = 5;
        string memory blockBuilderName = "kartik builder";
        (address bidder, uint256 bidderPk) = makeAddrAndKey("alice");
        (address provider, uint256 providerPk) = makeAddrAndKey("kartik");

        vm.deal(bidder, 200000 ether);
        vm.startPrank(bidder);
        bidderRegistry.prepay{value: 250 ether }();
        vm.stopPrank();

        vm.deal(provider, 200000 ether);
        vm.startPrank(provider);
        providerRegistry.registerAndStake{value: 250 ether}();
        vm.stopPrank();

        bytes32 index1 = constructAndStoreCommitment(bid, blockNumber, txn1, bidderPk, providerPk);
        bytes32 index2 = constructAndStoreCommitment(bid, blockNumber, txn2, bidderPk, providerPk);
        bytes32 index3 = constructAndStoreCommitment(bid, blockNumber, txn3, bidderPk, providerPk);
        bytes32 index4 = constructAndStoreCommitment(bid, blockNumber, txn4, bidderPk, providerPk);


        vm.startPrank(address(0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3));
        oracle.addBuilderAddress(blockBuilderName, provider);

        vm.expectEmit(true, false, false, true);
        emit CommitmentProcessed(index1, true);
        oracle.processBuilderCommitmentForBlockNumber(index1, blockNumber, blockBuilderName, true);
        vm.expectEmit(true, false, false, true);
        emit CommitmentProcessed(index2, true);
        oracle.processBuilderCommitmentForBlockNumber(index2, blockNumber, blockBuilderName, true);
        vm.expectEmit(true, false, false, true);
        emit CommitmentProcessed(index3, true);
        oracle.processBuilderCommitmentForBlockNumber(index3, blockNumber, blockBuilderName, true);
        vm.expectEmit(true, false, false, true);
        emit CommitmentProcessed(index4, true);
        oracle.processBuilderCommitmentForBlockNumber(index4, blockNumber, blockBuilderName, true);
        vm.stopPrank();
        assertEq(providerRegistry.checkStake(provider), 250 ether - bid*4);
        assertEq(bidderRegistry.getProviderAmount(provider), 0);
    }

    function test_process_commitment_reward_multiple() public {
        string memory txn1 = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d08";
        string memory txn2 = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d09";
        string memory txn3 = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d10";
        string memory txn4 = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d11";
        uint64 blockNumber = 201;
        uint64 bid = 5;
        string memory blockBuilderName = "kartik builder";
        (address bidder, uint256 bidderPk) = makeAddrAndKey("alice");
        (address provider, uint256 providerPk) = makeAddrAndKey("kartik");

        vm.deal(bidder, 200000 ether);
        vm.startPrank(bidder);
        bidderRegistry.prepay{value: 250 ether }();
        vm.stopPrank();

        vm.deal(provider, 200000 ether);
        vm.startPrank(provider);
        providerRegistry.registerAndStake{value: 250 ether}();
        vm.stopPrank();

        bytes32 index1 = constructAndStoreCommitment(bid, blockNumber, txn1, bidderPk, providerPk);
        assertEq(bidderRegistry.bidderPrepaidBalances(bidder), 250 ether - bid);
        bytes32 index2 = constructAndStoreCommitment(bid, blockNumber, txn2, bidderPk, providerPk);
        assertEq(bidderRegistry.bidderPrepaidBalances(bidder), 250 ether - 2*bid);
        bytes32 index3 = constructAndStoreCommitment(bid, blockNumber, txn3, bidderPk, providerPk);
        assertEq(bidderRegistry.bidderPrepaidBalances(bidder), 250 ether - 3*bid);
        bytes32 index4 = constructAndStoreCommitment(bid, blockNumber, txn4, bidderPk, providerPk);
        assertEq(bidderRegistry.bidderPrepaidBalances(bidder), 250 ether - 4*bid);

        vm.startPrank(address(0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3));
        oracle.addBuilderAddress(blockBuilderName, provider);

        vm.expectEmit(true, false, false, true);
        emit CommitmentProcessed(index1, false);
        oracle.processBuilderCommitmentForBlockNumber(index1, blockNumber, blockBuilderName, false);
        vm.expectEmit(true, false, false, true);
        emit CommitmentProcessed(index2, false);
        oracle.processBuilderCommitmentForBlockNumber(index2, blockNumber, blockBuilderName, false);
        vm.expectEmit(true, false, false, true);
        emit CommitmentProcessed(index3, false);
        oracle.processBuilderCommitmentForBlockNumber(index3, blockNumber, blockBuilderName, false);
        vm.expectEmit(true, false, false, true);
        emit CommitmentProcessed(index4, false);
        oracle.processBuilderCommitmentForBlockNumber(index4, blockNumber, blockBuilderName, false);
        vm.stopPrank();
        assertEq(providerRegistry.checkStake(provider), 250 ether);
        assertEq(bidderRegistry.getProviderAmount(provider), 4*bid);
    }


    function test_process_commitment_and_return() public {
        string memory txn = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d08";
        uint64 blockNumber = 200;
        uint64 bid = 2;
        (address bidder, uint256 bidderPk) = makeAddrAndKey("alice");
        (address provider, uint256 providerPk) = makeAddrAndKey("kartik");

        vm.deal(bidder, 200000 ether);
        vm.startPrank(bidder);
        bidderRegistry.prepay{value: 250 ether }();
        vm.stopPrank();

        vm.deal(provider, 200000 ether);
        vm.startPrank(provider);
        providerRegistry.registerAndStake{value: 250 ether}();
        vm.stopPrank();

        bytes32 index = constructAndStoreCommitment(bid, blockNumber, txn, bidderPk, providerPk);
        PreConfCommitmentStore.PreConfCommitment memory commitment = preConfCommitmentStore.getCommitment(index);

        vm.startPrank(address(0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3));
        bytes32[] memory commitments = new bytes32[](1);
        commitments[0] = commitment.commitmentHash;

        vm.expectEmit(true, false, false, true);
        emit FundsRetrieved(commitment.commitmentHash, bid);
        oracle.unlockFunds(commitments);
        
        
        assertEq(providerRegistry.checkStake(provider) , 250 ether);
        assertEq(bidderRegistry.bidderPrepaidBalances(bidder), 250 ether);
    }


    /**
    constructAndStoreCommitment is a helper function to construct and store a commitment
     */
    function constructAndStoreCommitment(
        uint64 bid,
        uint64 blockNumber,
        string memory txnHash,
        uint256 bidderPk,
        uint256 signerPk
    ) public returns (bytes32 commitmentIndex) {
        bytes32 bidHash = preConfCommitmentStore.getBidHash(
            txnHash,
            bid,
            blockNumber
        );


        (uint8 v,bytes32 r, bytes32 s) = vm.sign(bidderPk, bidHash);
        bytes memory bidSignature = abi.encodePacked(r, s, v);

        bytes32 commitmentHash = preConfCommitmentStore.getPreConfHash(
            txnHash,
            bid,
            blockNumber,
            bidHash,
            _bytesToHexString(bidSignature)
        );

        (v,r,s) = vm.sign(signerPk, commitmentHash);
        bytes memory commitmentSignature = abi.encodePacked(r, s, v);

        commitmentIndex = preConfCommitmentStore.storeCommitment(
            bid,
            blockNumber,
            txnHash,
            bidSignature,
            commitmentSignature
        );

        return commitmentIndex;
    }


    function _bytesToHexString(
        bytes memory _bytes
    ) public pure returns (string memory) {
        bytes memory HEXCHARS = "0123456789abcdef";
        bytes memory _string = new bytes(_bytes.length * 2);
        for (uint256 i = 0; i < _bytes.length; i++) {
            _string[i * 2] = HEXCHARS[uint8(_bytes[i] >> 4)];
            _string[1 + i * 2] = HEXCHARS[uint8(_bytes[i] & 0x0f)];
        }
        return string(_string);
    }

}
