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
        require(_txIndex < transactions.length, "MultiSigWallet: Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "MultiSigWallet: Transaction already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "MultiSigWallet: Transaction already confirmed by you");
        _;
    }

    //================================================================================
    // Constructor
    //================================================================================

    /**
     * @dev Initializes the multi-sig wallet with a set of owners and a required confirmation count.
     * @param _owners An array of initial owner addresses.
     * @param _requiredConfirmations The number of owners required to confirm a transaction.
     */
    constructor(address[] memory _owners, uint256 _requiredConfirmations) {
        require(_owners.length > 0, "MultiSigWallet: Owners required");
        require(
            _requiredConfirmations > 0 && _requiredConfirmations <= _owners.length,
            "MultiSigWallet: Invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "MultiSigWallet: Invalid owner address");
            require(!isOwner[owner], "MultiSigWallet: Duplicate owner");
            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredConfirmations = _requiredConfirmations;
    }

    //================================================================================
    // Fallback and Receive Functions
    //================================================================================

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    //================================================================================
    // Public and External Functions
    //================================================================================

    /**
     * @dev Allows an owner to submit a new transaction proposal.
     * @param _destination The target address for the transaction.
     * @param _value The amount of Ether to send with the transaction.
     * @param _data The calldata to be sent with the transaction.
     * @return txIndex The index of the newly created transaction.
     */
    function submitTransaction(address _destination, uint256 _value, bytes memory _data)
        public
        onlyOwner
        returns (uint256 txIndex)
    {
        txIndex = transactions.length;
        transactions.push(Transaction({
            destination: _destination,
            value: _value,
            data: _data,
            executed: false
        }));

        emit TransactionSubmitted(txIndex, msg.sender, _destination, _value, _data);

        // The submitter automatically confirms the transaction.
        _confirmTransaction(txIndex);

        return txIndex;
    }

    /**
     * @dev Allows an owner to confirm a pending transaction.
     * @param _txIndex The index of the transaction to confirm.
     */
    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
       _confirmTransaction(_txIndex);
    }

    /**
     * @dev Allows an owner to revoke their confirmation for a pending transaction.
     * @param _txIndex The index of the transaction to revoke confirmation for.
     */
    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        require(isConfirmed[_txIndex][msg.sender], "MultiSigWallet: You have not confirmed this transaction");
        isConfirmed[_txIndex][msg.sender] = false;
        emit ConfirmationRevoked(_txIndex, msg.sender);
    }

    /**
     * @dev Allows anyone to execute a transaction once it has enough confirmations.
     * @param _txIndex The index of the transaction to execute.
     */
    function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        uint256 confirmationCount = getConfirmationCount(_txIndex);
        require(
            confirmationCount >= requiredConfirmations,
            "MultiSigWallet: Not enough confirmations"
        );

        Transaction storage transaction = transactions[_txIndex];
        transaction.executed = true;

        (bool success, ) = transaction.destination.call{value: transaction.value}(transaction.data);
        require(success, "MultiSigWallet: Transaction execution failed");

        emit TransactionExecuted(_txIndex, msg.sender);
    }

    /**
     * @dev Adds a new owner. This action itself must be approved via a multi-sig transaction.
     * @param _newOwner The address of the new owner to add.
     */
    function addOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "MultiSigWallet: Invalid owner address");
        require(!isOwner[_newOwner], "MultiSigWallet: Owner already exists");
        isOwner[_newOwner] = true;
        owners.push(_newOwner);
        emit OwnerAdded(_newOwner);
    }
    
    /**
     * @dev Removes an existing owner. This action must be approved via a multi-sig transaction.
     * @param _oldOwner The address of the owner to remove.
     */
    function removeOwner(address _oldOwner) public onlyOwner {
        require(isOwner[_oldOwner], "MultiSigWallet: Address is not an owner");
        require(owners.length > 1, "MultiSigWallet: Cannot remove the last owner");

        isOwner[_oldOwner] = false;
        // Find and remove the owner from the array
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == _oldOwner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();

        if (requiredConfirmations > owners.length) {
            changeRequiredConfirmations(owners.length);
        }
