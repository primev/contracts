// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";


import {PreConfCommitmentStore} from "../contracts/PreConfirmations.sol";
import "../contracts/ProviderRegistry.sol";
import "../contracts/UserRegistry.sol";

contract TestPreConfCommitmentStore is Test {
    PreConfCommitmentStore internal preConfCommitmentStore;
    uint16 internal feePercent;
    uint256 internal minStake;
    address internal provider;
    address internal feeRecipient;
    ProviderRegistry internal providerRegistry;
    uint256 testNumber;
    uint64 testNumber2;

    UserRegistry internal userRegistry;

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
    }

    function test_Initialize() public {
        assertEq(preConfCommitmentStore.oracle(), feeRecipient);
        assertEq(
            address(preConfCommitmentStore.providerRegistry()),
            address(providerRegistry)
        );
        assertEq(
            address(preConfCommitmentStore.userRegistry()),
            address(userRegistry)
        );
    }

    function test_CreateCommitment() public {
        bytes32 bidHash = preConfCommitmentStore.getBidHash(
            "0xkartik",
            200 wei,
            3000
        );
        (address user, uint256 userPk) = makeAddrAndKey("alice");
        // Wallet memory kartik = vm.createWallet('test wallet');
        (uint8 v,bytes32 r, bytes32 s) = vm.sign(userPk, bidHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.deal(user, 200000 ether);
        vm.prank(user);
        userRegistry.registerAndStake{value: 1e18 wei}();
        (bytes32 digest, address recoveredAddress, uint256 stake) =  preConfCommitmentStore.verifyBid(200 wei, 3000, "0xkartik", signature);
        
        assertEq(stake, 1e18 wei);
        assertEq(user, recoveredAddress);
        assertEq(digest, bidHash);

        preConfCommitmentStore.storeCommitment(200 wei, 3000, "0xkartik", "0xkartik", signature, signature);

    }

    function test_UpdateOracle() public {
        preConfCommitmentStore.updateOracle(feeRecipient);
        assertEq(preConfCommitmentStore.oracle(), feeRecipient);
    }

    function test_UpdateProviderRegistry() public {
        preConfCommitmentStore.updateProviderRegistry(feeRecipient);
        assertEq(
            address(preConfCommitmentStore.providerRegistry()),
            feeRecipient
        );
    }

    function test_UpdateUserRegistry() public {
        preConfCommitmentStore.updateUserRegistry(feeRecipient);
        assertEq(address(preConfCommitmentStore.userRegistry()), feeRecipient);
    }

    function test_GetBidHash() public {
        string memory hash = "0xkartik";

        bytes32 bidHash = preConfCommitmentStore.getBidHash(
            hash,
            testNumber2,
            testNumber2
        );
        assertEq(
            bidHash,
            0x86ac45fb1e987a6c8115494cd4fd82f6756d359022cdf5ea19fd2fac1df6e7f0
        );
    }

    function test_GetPreConfHash() public {
        string memory hash = "0xkartik";
        string
            memory signsing = "33683da4605067c9491d665864b2e4e7ade8bc57921da9f192a1b8246a941eaa2fb90f72031a2bf6008fa590158591bb5218c9aace78ad8cf4d1f2f4d74bc3e901";
        bytes32 preConfHash = preConfCommitmentStore.getPreConfHash(
            hash,
            testNumber2,
            testNumber2,
            0x86ac45fb1e987a6c8115494cd4fd82f6756d359022cdf5ea19fd2fac1df6e7f0,
            signsing
        );
        assertEq(
            preConfHash,
            0x31dca6c6fd15593559dabb9e25285f727fd33f07e17ec2e8da266706020034dc
        );
    }

    function _bytes32ToHexString(
        bytes32 _bytes32
    ) internal pure returns (string memory) {
        bytes memory HEXCHARS = "0123456789abcdef";
        bytes memory _string = new bytes(64);
        for (uint8 i = 0; i < 32; i++) {
            _string[i * 2] = HEXCHARS[uint8(_bytes32[i] >> 4)];
            _string[1 + i * 2] = HEXCHARS[uint8(_bytes32[i] & 0x0f)];
        }
        return string(_string);
    }

    function test_StoreCommitment() public {
        address signer = 0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3;
        vm.deal(signer, 5 ether);
        vm.prank(signer);
        userRegistry.registerAndStake{value: 2 ether}();
        string memory txnHash = "0xkartik";
        string
            memory commitmentHash = "0x31dca6c6fd15593559dabb9e25285f727fd33f07e17ec2e8da266706020034dc";
        bytes
            memory signature = "0xb170d082db1bf77fa0b589b9438444010dcb1e6dd326b661b02eb92abe4c066e243bb0d214b01667750ba2c53ff1ab445fd784b441dbc1f30280c379f002cc571c";
        uint64 bid = 2;
        uint64 blockNumber = 2;
        bytes memory bidSignature = bytes(
            hex"c10688ea554c1dae605619fa7f75103fb483ab6b5ad424e4e232f5da4449503a27ef6aed49b85bfd0e598650831c861a55a5eb197d9279d6a5667efaa46ab8831c"
        );
        bytes
            memory commitmentSignature = hex"ff7e00cf5c2d0fa9ef7c5efdca68b285a664a3aab927eb779b464207f537551f4ff81b085acf78b58ecb8c96c9a4efcb2172a0287f5bf5819b49190f6e2d2d1e1b";

        // Step 1: Verify that the commitment has not been used before
        verifyCommitmentNotUsed(txnHash, bid, blockNumber, signature);

        // Step 2: Store the commitment
        bytes32 index = storeCommitment(
            bid,
            blockNumber,
            txnHash,
            commitmentHash,
            bidSignature,
            commitmentSignature
        );

        // Step 3: Verify the stored commitment
        verifyStoredCommitment(
            index,
            bid,
            blockNumber,
            txnHash,
            commitmentHash,
            bidSignature,
            commitmentSignature
        );
    }

    function verifyCommitmentNotUsed(
        string memory txnHash,
        uint64 bid,
        uint64 blockNumber,
        bytes memory bidSignature
    ) public returns (bytes32) {
        bytes32 bidHash = preConfCommitmentStore.getBidHash(
            txnHash,
            bid,
            blockNumber
        );
        bytes32 preConfHash = preConfCommitmentStore.getPreConfHash(
            txnHash,
            bid,
            blockNumber,
            bidHash,
            _bytesToHexString(bidSignature)
        );

        (bool commitmentUsed, , , , , , , , , ) = preConfCommitmentStore
            .commitments(preConfHash);
        assertEq(commitmentUsed, false);

        return bidHash;
    }

    function storeCommitment(
        uint64 bid,
        uint64 blockNumber,
        string memory txnHash,
        string memory commitmentHash,
        bytes memory bidSignature,
        bytes memory commitmentSignature
    ) internal returns (bytes32) {
        bytes32 commitmentIndex = preConfCommitmentStore.storeCommitment(
            bid,
            blockNumber,
            txnHash,
            commitmentHash,
            bidSignature,
            commitmentSignature
        );

        return commitmentIndex;
    }

    function verifyStoredCommitment(
        bytes32 index,
        uint64 bid,
        uint64 blockNumber,
        string memory txnHash,
        string memory commitmentHash,
        bytes memory bidSignature,
        bytes memory commitmentSignature
    ) public {

        bytes32 reconstructedIndex = keccak256(
            abi.encodePacked(
                commitmentHash,
                commitmentSignature
            )
        );

        (PreConfCommitmentStore.PreConfCommitment memory commitment) = preConfCommitmentStore
            .getCommitment(index);

        (, address commiterAddress) = preConfCommitmentStore.verifyPreConfCommitment(
            txnHash,
            bid,
            blockNumber,
            commitment.bidHash,
            bidSignature,
            commitmentSignature
        );

        bytes32[] memory commitments = preConfCommitmentStore.getCommitmentsByCommitter(commiterAddress);
        
        assert(commitments.length >= 1);

        assertEq(
            index,
            reconstructedIndex,
            "Returned hash should match the preConfHash"
        );
        assertEq(
            commitment.commitmentUsed,
            false,
            "Commitment should have been marked as used"
        );
        assertEq(commitment.bid, bid, "Stored bid should match input bid");
        assertEq(
            commitment.blockNumber,
            blockNumber,
            "Stored blockNumber should match input blockNumber"
        );
        assertEq(
            commitment.txnHash,
            txnHash,
            "Stored txnHash should match input txnHash"
        );
        assertEq(
            commitment.commitmentHash,
            commitmentHash,
            "Stored commitmentHash should match input commitmentHash"
        );
        assertEq(
            commitment.bidSignature,
            bidSignature,
            "Stored bidSignature should match input bidSignature"
        );
        assertEq(
            commitment.commitmentSignature,
            commitmentSignature,
            "Stored commitmentSignature should match input commitmentSignature"
        );
    }

    function test_GetCommitment() public {
        address signer = 0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3;
        vm.deal(signer, 5 ether);
        vm.prank(signer);
        userRegistry.registerAndStake{value: 2 ether}();
        string memory txnHash = "0xkartik";
        string
            memory commitmentHash = "0x31dca6c6fd15593559dabb9e25285f727fd33f07e17ec2e8da266706020034dc";
        bytes
            memory signature = "0xb170d082db1bf77fa0b589b9438444010dcb1e6dd326b661b02eb92abe4c066e243bb0d214b01667750ba2c53ff1ab445fd784b441dbc1f30280c379f002cc571c";
        uint64 bid = 2;
        uint64 blockNumber = 2;
        bytes memory bidSignature = bytes(
            hex"c10688ea554c1dae605619fa7f75103fb483ab6b5ad424e4e232f5da4449503a27ef6aed49b85bfd0e598650831c861a55a5eb197d9279d6a5667efaa46ab8831c"
        );
        bytes
            memory commitmentSignature = hex"ff7e00cf5c2d0fa9ef7c5efdca68b285a664a3aab927eb779b464207f537551f4ff81b085acf78b58ecb8c96c9a4efcb2172a0287f5bf5819b49190f6e2d2d1e1b";

        // Step 1: Verify that the commitment has not been used before
        verifyCommitmentNotUsed(txnHash, bid, blockNumber, signature);

        // Step 2: Store the commitment
        bytes32 preConfHash = storeCommitment(
            bid,
            blockNumber,
            txnHash,
            commitmentHash,
            bidSignature,
            commitmentSignature
        );
        PreConfCommitmentStore.PreConfCommitment
            memory storedCommitment = preConfCommitmentStore.getCommitment(
                preConfHash
            );
        
        assertEq(storedCommitment.bid, bid);
        assertEq(storedCommitment.blockNumber, blockNumber);
        assertEq(storedCommitment.txnHash, txnHash);
    }

    function test_InitiateSlash() public {
        // Assuming you have a stored commitment
        {
            address signer = 0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3;
            vm.deal(signer, 5 ether);
            vm.prank(signer);
            userRegistry.registerAndStake{value: 2 ether}();
            string memory txnHash = "0xkartik";
            string
                memory commitmentHash = "0x31dca6c6fd15593559dabb9e25285f727fd33f07e17ec2e8da266706020034dc";
            bytes
                memory signature = "0xb170d082db1bf77fa0b589b9438444010dcb1e6dd326b661b02eb92abe4c066e243bb0d214b01667750ba2c53ff1ab445fd784b441dbc1f30280c379f002cc571c";
            uint64 bid = 2;
            uint64 blockNumber = 2;
            bytes memory bidSignature = bytes(
                hex"c10688ea554c1dae605619fa7f75103fb483ab6b5ad424e4e232f5da4449503a27ef6aed49b85bfd0e598650831c861a55a5eb197d9279d6a5667efaa46ab8831c"
            );
            address commiter = 0xE3E9cc6677B1b7f05C483168bf25B4D9604c6763;
            bytes
                memory commitmentSignature = hex"306eb646b8882c8cd918d4aff61cbf6814a152becbc84b52abb4aad963dbaa2465c0c27837b5f8c943cb1c523f54961c0c8775c48d9dbf7ae9883b14925794941c";

            // Step 1: Verify that the commitment has not been used before
            bytes32 bidHash = verifyCommitmentNotUsed(
                txnHash,
                bid,
                blockNumber,
                signature
            );

            bytes32 preConfHash = preConfCommitmentStore.getPreConfHash(
                txnHash,
                bid,
                blockNumber,
                bidHash,
                _bytesToHexString(bidSignature)
            );

            // Verify that the commitment has not been used before
            (bool commitmentUsed, , , , , , , , , ) = preConfCommitmentStore
                .commitments(preConfHash);
            assert(commitmentUsed == false);
            bytes32 index = preConfCommitmentStore.storeCommitment(
                bid,
                blockNumber,
                txnHash,
                commitmentHash,
                bidSignature,
                commitmentSignature
            );
            providerRegistry.setPreconfirmationsContract(
                address(preConfCommitmentStore)
            );

            vm.deal(commiter, 5 ether);
            vm.prank(commiter);
            providerRegistry.registerAndStake{value: 4 ether}();
            vm.prank(feeRecipient);
            preConfCommitmentStore.initiateSlash(index);

            (commitmentUsed, , , , , , , , , ) = preConfCommitmentStore
                .commitments(index);
            // Verify that the commitment has been marked as used
            assert(commitmentUsed == true);
        }
    }

    function test_InitiateReward() public {
        // Assuming you have a stored commitment
        {
            address signer = 0x6d503Fd50142C7C469C7c6B64794B55bfa6883f3;
            vm.deal(signer, 5 ether);
            vm.prank(signer);
            userRegistry.registerAndStake{value: 2 ether}();
            string memory txnHash = "0xkartik";
            string
                memory commitmentHash = "0x31dca6c6fd15593559dabb9e25285f727fd33f07e17ec2e8da266706020034dc";
            bytes
                memory signature = "0xb170d082db1bf77fa0b589b9438444010dcb1e6dd326b661b02eb92abe4c066e243bb0d214b01667750ba2c53ff1ab445fd784b441dbc1f30280c379f002cc571c";
            uint64 bid = 2;
            uint64 blockNumber = 2;
            bytes memory bidSignature = bytes(
                hex"c10688ea554c1dae605619fa7f75103fb483ab6b5ad424e4e232f5da4449503a27ef6aed49b85bfd0e598650831c861a55a5eb197d9279d6a5667efaa46ab8831c"
            );
            address commiter = 0xE3E9cc6677B1b7f05C483168bf25B4D9604c6763;
            bytes
                memory commitmentSignature = hex"306eb646b8882c8cd918d4aff61cbf6814a152becbc84b52abb4aad963dbaa2465c0c27837b5f8c943cb1c523f54961c0c8775c48d9dbf7ae9883b14925794941c";

            // Step 1: Verify that the commitment has not been used before
            bytes32 bidHash = verifyCommitmentNotUsed(
                txnHash,
                bid,
                blockNumber,
                signature
            );

            bytes32 preConfHash = preConfCommitmentStore.getPreConfHash(
                txnHash,
                bid,
                blockNumber,
                bidHash,
                _bytesToHexString(bidSignature)
            );

            // Verify that the commitment has not been used before
            (bool commitmentUsed, , , , , , , , , ) = preConfCommitmentStore
                .commitments(preConfHash);
            assert(commitmentUsed == false);
            bytes32 index = preConfCommitmentStore.storeCommitment(
                bid,
                blockNumber,
                txnHash,
                commitmentHash,
                bidSignature,
                commitmentSignature
            );

            userRegistry.setPreconfirmationsContract(
                address(preConfCommitmentStore)
            );
            vm.deal(commiter, 5 ether);
            vm.prank(commiter);
            providerRegistry.registerAndStake{value: 4 ether}();
            vm.prank(feeRecipient);
            preConfCommitmentStore.initateReward(index);

            (commitmentUsed, , , , , , , , , ) = preConfCommitmentStore
                .commitments(index);
            // Verify that the commitment has been marked as used
            assert(commitmentUsed == true);
        }
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
