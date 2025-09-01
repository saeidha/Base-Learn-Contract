// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address[] public owners;
    address public owner1 = address(0x1);
    address public owner2 = address(0x2);
    address public owner3 = address(0x3);
    address public nonOwner = address(0x4);
    address public destination = address(0x5);
    uint256 public constant REQUIRED_CONFIRMATIONS = 2;

    event TransactionSubmitted(uint256 indexed txIndex, address indexed owner, address indexed destination, uint256 value, bytes data);
    event TransactionConfirmed(uint256 indexed txIndex, address indexed owner);
    event ConfirmationRevoked(uint256 indexed txIndex, address indexed owner);
    event TransactionExecuted(uint256 indexed txIndex, address indexed owner);

    // This function runs before each test case
    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);
        wallet = new MultiSigWallet(owners, REQUIRED_CONFIRMATIONS);

        // Fund the wallet with 10 ETH for execution tests
        vm.deal(address(wallet), 10 ether);
    }

    //================================================================================
    // 1. Deployment Tests
    //================================================================================

    function test_InitialState() public {
        assertEq(wallet.requiredConfirmations(), REQUIRED_CONFIRMATIONS);
        address[] memory deployedOwners = wallet.getOwners();
        assertEq(deployedOwners.length, 3);
        assertEq(deployedOwners[0], owner1);
        assertEq(deployedOwners[1], owner2);
        assertEq(deployedOwners[2], owner3);
    }

    function test_Fail_DeployWithZeroOwners() public {
        address[] memory emptyOwners;
        vm.expectRevert("MultiSigWallet: Owners required");
        new MultiSigWallet(emptyOwners, 1);
    }

    function test_Fail_DeployWithInvalidRequirement() public {
        vm.expectRevert("MultiSigWallet: Invalid number of required confirmations");
        new MultiSigWallet(owners, 0);

        vm.expectRevert("MultiSigWallet: Invalid number of required confirmations");
        new MultiSigWallet(owners, owners.length + 1);
    }

    //================================================================================
    // 2. Transaction Submission Tests
    //================================================================================

    function test_OwnerCanSubmitTransaction() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(destination, 1 ether, "");
        assertEq(txIndex, 0);

        (address dest, uint256 val, , bool executed) = wallet.getTransaction(txIndex);
        assertEq(dest, destination);
        assertEq(val, 1 ether);
        assertEq(executed, false);
    }

    function test_SubmitterAutomaticallyConfirms() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(destination, 1 ether, "");
        assertTrue(wallet.isConfirmed(txIndex, owner1));
        assertEq(wallet.getConfirmationCount(txIndex), 1);
    }

    function test_Fail_NonOwnerCannotSubmitTransaction() public {
        vm.prank(nonOwner);
        vm.expectRevert("MultiSigWallet: Not an owner");
        wallet.submitTransaction(destination, 1 ether, "");
    }

    //================================================================================
    // 3. Confirmation and Revocation Tests
    //================================================================================

    function test_OwnerCanConfirmTransaction() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(destination, 1 ether, "");

        vm.prank(owner2);
        vm.expectEmit(true, true, true, true);
        emit TransactionConfirmed(txIndex, owner2);
        wallet.confirmTransaction(txIndex);
        
        assertTrue(wallet.isConfirmed(txIndex, owner2));
        assertEq(wallet.getConfirmationCount(txIndex), 2);
    }

    function test_Fail_CannotConfirmTwice() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(destination, 1 ether, "");

        vm.prank(owner1);
        vm.expectRevert("MultiSigWallet: Transaction already confirmed by you");
        wallet.confirmTransaction(txIndex);
    }

    function test_OwnerCanRevokeConfirmation() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(destination, 1 ether, ""); // owner1 confirms
        
        vm.prank(owner1);
        vm.expectEmit(true, true, false, true); // Don't check data
        emit ConfirmationRevoked(txIndex, owner1);
        wallet.revokeConfirmation(txIndex);
        
        assertFalse(wallet.isConfirmed(txIndex, owner1));
        assertEq(wallet.getConfirmationCount(txIndex), 0);
    }
    
    function test_Fail_CannotRevokeIfNotConfirmed() public {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(destination, 1 ether, "");
        
        vm.prank(owner2); // owner2 hasn't confirmed
        vm.expectRevert("MultiSigWallet: You have not confirmed this transaction");
        wallet.revokeConfirmation(txIndex);
    }

    //================================================================================
    // 4. Transaction Execution Tests
    //================================================================================
    
    function test_CanExecuteWithEnoughConfirmations() public {
        // Step 1: Submit
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(destination, 1 ether, "");
        
        // Step 2: Confirm
        vm.prank(owner2);
