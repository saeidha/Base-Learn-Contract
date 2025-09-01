// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MultiSigWallet
 * @dev A wallet that requires multiple owners to confirm a transaction before execution.
 * This contract is a foundational DeFi primitive, designed for security and gas efficiency.
 */
contract MultiSigWallet {
    //================================================================================
    // Events
    //================================================================================

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event TransactionSubmitted(
        uint256 indexed txIndex,
        address indexed owner,
        address indexed destination,
        uint256 value,
        bytes data
    );
    event TransactionConfirmed(uint256 indexed txIndex, address indexed owner);
    event ConfirmationRevoked(uint256 indexed txIndex, address indexed owner);
    event TransactionExecuted(uint256 indexed txIndex, address indexed owner);
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed oldOwner);
    event RequiredConfirmationsChanged(uint256 newRequiredConfirmations);

    //================================================================================
    // State Variables
