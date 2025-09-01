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
    //================================================================================

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    // Mapping from transaction index to the transaction details.
    Transaction[] public transactions;

    // Mapping from transaction index to a mapping of owner addresses to their confirmation status.
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    // Array of owner addresses.
    address[] public owners;

    // Mapping to check if an address is an owner for efficient lookups.
    mapping(address => bool) public isOwner;

    // The required number of confirmations for a transaction to be executed.
    uint256 public requiredConfirmations;

    //================================================================================
    // Modifiers
    //================================================================================

    modifier onlyOwner() {
        require(isOwner[msg.sender], "MultiSigWallet: Not an owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
