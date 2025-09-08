// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title TimeLockWallet
 * @dev A contract that allows an owner to deposit funds and allocate them to beneficiaries.
 * Beneficiaries can withdraw their allocated funds only after a predefined unlock timestamp.
 * Includes pause functionality.
 */
contract TimeLockWallet is Ownable, Pausable {

    // =============================================================
    //                           Structs
    // =============================================================

    struct Beneficiary {
        bool isActive;          // True if the beneficiary is currently active
        uint256 amountLocked;   // Total amount allocated to this beneficiary
        uint256 unlockTimestamp; // Timestamp after which the beneficiary can withdraw
        uint256 withdrawnAmount; // Amount already withdrawn by this beneficiary
    }

    // =============================================================
    //                         State Variables
    // =============================================================

    mapping(address => Beneficiary) public beneficiaries;
    uint256 public beneficiaryCount; // Tracks the number of *active* beneficiaries
    uint256 public totalLockedFunds; // Sum of all 'amountLocked' for active beneficiaries

    // =============================================================
    //                             Events
    // =============================================================

    event DepositMade(address indexed sender, uint256 amount, uint256 newContractBalance);
    event BeneficiaryAdded(address indexed beneficiary, uint256 amount, uint256 unlockTime);
    event BeneficiaryUpdated(address indexed beneficiary, uint256 oldAmount, uint256 newAmount, uint256 oldUnlockTime, uint256 newUnlockTime);
    event FundsWithdrawn(address indexed beneficiary, uint256 amount);
    event UnlockTimeExtended(address indexed beneficiary, uint256 oldUnlockTime, uint256 newUnlockTime);
    event BeneficiaryRemoved(address indexed beneficiary, uint256 remainingLockedAmount);
    event OwnerFundsWithdrawn(address indexed owner, uint256 amount);

    // =============================================================
    //                            Modifiers
    // =============================================================

    modifier beneficiaryExists(address _beneficiary) {
        require(beneficiaries[_beneficiary].isActive, "TLW: Beneficiary does not exist or is inactive");
        _;
    }

    modifier notBeneficiary(address _addr) {
        require(!beneficiaries[_addr].isActive, "TLW: Address is already an active beneficiary");
        _;
    }

    // =============================================================
    //                          Constructor
    // =============================================================

    constructor() Ownable(msg.sender) {}

    // =============================================================
    //                     Owner/Admin Functions
    // =============================================================

    /**
     * @notice Allows the owner to deposit funds into the TimeLockWallet.
     * @dev Funds deposited here are available to be allocated to beneficiaries or withdrawn by owner (if unallocated).
     */
    function deposit() external payable onlyOwner whenNotPaused {
        require(msg.value > 0, "TLW: Deposit amount must be greater than zero");
        emit DepositMade(msg.sender, msg.value, address(this).balance);
    }

    /**
     * @notice Adds a new beneficiary with a specified amount and unlock timestamp.
     * @param _beneficiary The address of the new beneficiary.
     * @param _amount The amount of funds to allocate to this beneficiary.
     * @param _unlockTimestamp The timestamp after which the beneficiary can withdraw.
     */
    function addBeneficiary(address _beneficiary, uint256 _amount, uint256 _unlockTimestamp)
        external
        onlyOwner
        whenNotPaused
        notBeneficiary(_beneficiary)
    {
        require(_beneficiary != address(0), "TLW: Invalid beneficiary address");
        require(_amount > 0, "TLW: Amount must be greater than zero");
        require(address(this).balance >= totalLockedFunds + _amount, "TLW: Insufficient contract balance to lock funds");
        require(_unlockTimestamp > block.timestamp, "TLW: Unlock timestamp must be in the future");

        beneficiaries[_beneficiary] = Beneficiary({
            isActive: true,
            amountLocked: _amount,
            unlockTimestamp: _unlockTimestamp,
            withdrawnAmount: 0
        });
        totalLockedFunds += _amount;
        beneficiaryCount++;
        emit BeneficiaryAdded(_beneficiary, _amount, _unlockTimestamp);
    }

    /**
     * @notice Updates the allocated amount for an existing beneficiary.
     * @dev Can increase or decrease the amount. Adjusts totalLockedFunds accordingly.
     * @param _beneficiary The address of the beneficiary.
     * @param _newAmount The new amount to allocate to this beneficiary.
     */
    function updateBeneficiaryAmount(address _beneficiary, uint256 _newAmount)
        external
        onlyOwner
        whenNotPaused
        beneficiaryExists(_beneficiary)
    {
        require(_newAmount > 0, "TLW: New amount must be greater than zero");
        
