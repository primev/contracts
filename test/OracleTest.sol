// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/Oracle.sol";
import "../contracts/PreConfirmations.sol";
import "../contracts/interfaces/IPreConfirmations.sol";
import "../contracts/ProviderRegistry.sol";
import "../contracts/UserRegistry.sol";

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
    UserRegistry internal userRegistry;


    // Events to match against
    event BlockDataRequested(uint256 blockNumber);
    event BlockDataReceived(string[] txnList, uint256 blockNumber, string blockBuilderName);
    event CommitmentProcessed(bytes32 commitmentHash, bool isSlash);

    function setUp() public {
        testNumber = 2;
        testNumber2 = 2;

        feePercent = 10;
        minStake = 1e18 wei;
        feeRecipient = vm.addr(9);

        providerRegistry = new ProviderRegistry(
            minStake,
            feeRecipient,
            feePercent
        );
        userRegistry = new UserRegistry(minStake, feeRecipient, feePercent);

        preConfCommitmentStore = new PreConfCommitmentStore(
            address(providerRegistry), // Provider Registry
            address(userRegistry), // User Registry
            feeRecipient // Oracle
        );

        address owner = 0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3;
        vm.deal(owner, 5 ether);
        vm.startPrank(owner);
        userRegistry.registerAndStake{value: 2 ether}();
        
        // vm.prank(owner);
        oracle = new Oracle(address(preConfCommitmentStore));
        oracle.addBuilderAddress("mev builder", owner);
        vm.stopPrank();

        preConfCommitmentStore.updateOracle(address(oracle));
        userRegistry.setPreconfirmationsContract(address(preConfCommitmentStore));
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
        (address user, uint256 userPk) = makeAddrAndKey("k builder");
        (address provider, uint256 providerPk) = makeAddrAndKey("primev builder");
        (address builder3,) = makeAddrAndKey("titan builder");
        (address builder4,) = makeAddrAndKey("zk builder");

        oracle.addBuilderAddress("titan builder", builder3);
        oracle.addBuilderAddress("zk builder", builder4);

        assertEq(oracle.blockBuilderNameToAddress("titan builder"), builder3);
        assertEq(oracle.blockBuilderNameToAddress("zk builder"), builder4);
        vm.stopPrank();

        vm.deal(user, 1000 ether);
        vm.deal(provider, 1000 ether);

        vm.startPrank(user);
        userRegistry.registerAndStake{value: 250 ether }();
        vm.stopPrank();

        vm.startPrank(provider);
        providerRegistry.registerAndStake{value: 250 ether}();
        vm.stopPrank();

        constructAndStoreCommitment(2, 2, "0xkartik", userPk, providerPk);

        string[] memory txnList = new string[](1);
        txnList[0] = string(abi.encodePacked(keccak256("0xkartik")));
        oracle.receiveBlockData(txnList, 2, "primev builder");

        assertEq(userRegistry.getProviderAmount(provider), 0);
        assertEq(providerRegistry.checkStake(provider), 250 ether);
    }

    function test_RequestBlockData() public {
        address signer = 0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3;
        vm.deal(signer, 5 ether);
        vm.prank(signer);
        uint256 blockNumber = block.number;
        vm.expectEmit();
        emit BlockDataRequested(blockNumber);
        oracle.requestBlockData(blockNumber);
    }

    function test_ReceiveBlockData() public {
        string[] memory txnList = new string[](1);
        txnList[0] = string(abi.encodePacked(keccak256("0xkartik")));
        uint256 blockNumber = block.number;
        string memory blockBuilderName = "mev builder";
        vm.expectEmit(true, true, false, true);
        emit BlockDataReceived(txnList, blockNumber, blockBuilderName);
        oracle.receiveBlockData(txnList, blockNumber, blockBuilderName);
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

    function test_ReceiveBlockDataWithCommitments() public {
        string[] memory txnList = new string[](1);
        txnList[0] = "0x6d9c53ad81249775f8c082b11ac293b2e19194ff791bd1c4fd37683310e90d08";
        uint64 blockNumber = 200;
        uint64 bid = 2;
        string memory blockBuilderName = "kartik builder";
        (address user, uint256 userPk) = makeAddrAndKey("alice");
        (address provider, uint256 providerPk) = makeAddrAndKey("kartik");

        vm.deal(user, 200000 ether);
        vm.startPrank(user);
        userRegistry.registerAndStake{value: 250 ether }();
        vm.stopPrank();

        vm.deal(provider, 200000 ether);
        vm.startPrank(provider);
        providerRegistry.registerAndStake{value: 250 ether}();
        vm.stopPrank();

        bytes memory txnhashList = abi.encode(txnList);

        constructAndStoreCommitment(bid, blockNumber, string(txnhashList), userPk, providerPk);
        vm.prank(address(0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3));
        oracle.addBuilderAddress("kartik builder", provider);
        vm.expectEmit(true, true, false, true);
        emit BlockDataReceived(txnList, blockNumber, blockBuilderName);
        oracle.receiveBlockData(txnList, blockNumber, blockBuilderName);

        bytes32[] memory commitmentHashes = preConfCommitmentStore.getCommitmentsByBlockNumber(blockNumber);
        assertEq(commitmentHashes.length, 1);
        assertEq(userRegistry.getProviderAmount(provider), bid);

    }


    function test_ReceiveBlockDataWithCommitmentsSlashed() public {
        string[] memory txnList = new string[](1);
        txnList[0] = string(abi.encodePacked(keccak256("0xkartik")));
        uint64 blockNumber = 200;
        uint64 bid = 2;
        string memory blockBuilderName = "kartik builder";
        (address user, uint256 userPk) = makeAddrAndKey("alice");
        (address provider, uint256 providerPk) = makeAddrAndKey("bob");

        vm.deal(user, 200000 ether);
        vm.deal(provider, 200000 ether);

        vm.startPrank(user);
        userRegistry.registerAndStake{value: 250 ether }();
        vm.stopPrank();

        vm.startPrank(provider);
        providerRegistry.registerAndStake{value: 250 ether}();
        vm.stopPrank();

        uint256 ogStake = providerRegistry.checkStake(provider);

        string[] memory commitedTxnList = new string[](1);
        commitedTxnList[0] = string(abi.encodePacked(keccak256("0xSlash")));
        constructAndStoreCommitment(bid, blockNumber, string(abi.encode(commitedTxnList)), userPk, providerPk);
        vm.prank(address(0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3));
        oracle.addBuilderAddress("kartik builder", provider);
        vm.expectEmit(true, true, false, true);
        emit BlockDataReceived(txnList, blockNumber, blockBuilderName);
        oracle.receiveBlockData(txnList, blockNumber, blockBuilderName);

        bytes32[] memory commitmentHashes = preConfCommitmentStore.getCommitmentsByBlockNumber(blockNumber);
        assertEq(commitmentHashes.length, 1);
        
        // Ensuring no rewards
        assertEq(userRegistry.getProviderAmount(provider), 0);

        // Detect slashing
        uint256 postSlashStake = providerRegistry.checkStake(provider);
        assertEq(postSlashStake + bid, ogStake);
        assertEq(userRegistry.checkStake(user), 250 ether);

    }

    // function test_ProcessCommitment_Slash() public {
    //   TODO(@ckartik): Add test
    // }

    function test_ProcessCommitment_Reward() public {

         string memory txnHash = "0xkartik";
         /*
         Temporarily hardcoding the values for the following variables for future testing.
        string
            memory cHash = "0x31dca6c6fd15593559dabb9e25285f727fd33f07e17ec2e8da266706020034dc";
        bytes
            memory signature = "0xb170d082db1bf77fa0b589b9438444010dcb1e6dd326b661b02eb92abe4c066e243bb0d214b01667750ba2c53ff1ab445fd784b441dbc1f30280c379f002cc571c";
        */
        uint64 bid = 2;
        uint64 blockNumber = 2;
        bytes memory bidSignature = bytes(
            hex"c10688ea554c1dae605619fa7f75103fb483ab6b5ad424e4e232f5da4449503a27ef6aed49b85bfd0e598650831c861a55a5eb197d9279d6a5667efaa46ab8831c"
        );
        bytes
            memory commitmentSignature = hex"ff7e00cf5c2d0fa9ef7c5efdca68b285a664a3aab927eb779b464207f537551f4ff81b085acf78b58ecb8c96c9a4efcb2172a0287f5bf5819b49190f6e2d2d1e1b";
        bytes32 commitmentIndex = preConfCommitmentStore.storeCommitment(bid, blockNumber, txnHash, bidSignature, commitmentSignature);

        bool isSlash = false;
        vm.expectEmit(true, false, false, true);
        emit CommitmentProcessed(commitmentIndex, isSlash);
        oracle.processCommitment(commitmentIndex, isSlash);
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
