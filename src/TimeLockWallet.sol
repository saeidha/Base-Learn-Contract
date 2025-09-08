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
        
        Beneficiary storage b = beneficiaries[_beneficiary];
        require(_newAmount >= b.withdrawnAmount, "TLW: New amount cannot be less than withdrawn amount");

        uint256 oldAmount = b.amountLocked;
        if (_newAmount > oldAmount) {
            uint256 amountToIncrease = _newAmount - oldAmount;
            require(address(this).balance >= (totalLockedFunds + amountToIncrease), "TLW: Insufficient contract balance for increase");
            totalLockedFunds += amountToIncrease;
        } else if (_newAmount < oldAmount) {
            uint256 amountToDecrease = oldAmount - _newAmount;
            totalLockedFunds -= amountToDecrease;
        }
        
        b.amountLocked = _newAmount;
        emit BeneficiaryUpdated(_beneficiary, oldAmount, _newAmount, b.unlockTimestamp, b.unlockTimestamp);
    }

    /**
     * @notice Updates the unlock timestamp for an existing beneficiary.
     * @param _beneficiary The address of the beneficiary.
     * @param _newUnlockTimestamp The new timestamp after which the beneficiary can withdraw.
     */
    function updateBeneficiaryUnlockTime(address _beneficiary, uint256 _newUnlockTimestamp)
        external
        onlyOwner
        whenNotPaused
        beneficiaryExists(_beneficiary)
    {
        require(_newUnlockTimestamp > block.timestamp, "TLW: New unlock timestamp must be in the future");
        require(_newUnlockTimestamp != beneficiaries[_beneficiary].unlockTimestamp, "TLW: New unlock timestamp is same as current");

        uint256 oldUnlockTimestamp = beneficiaries[_beneficiary].unlockTimestamp;
        beneficiaries[_beneficiary].unlockTimestamp = _newUnlockTimestamp;
        emit BeneficiaryUpdated(_beneficiary, beneficiaries[_beneficiary].amountLocked, beneficiaries[_beneficiary].amountLocked, oldUnlockTimestamp, _newUnlockTimestamp);
    }

    /**
     * @notice Extends the unlock timestamp for an existing beneficiary.
     * @dev Only allows setting a timestamp further in the future than the current one.
     * @param _beneficiary The address of the beneficiary.
     * @param _newUnlockTimestamp The new, later timestamp.
     */
    function extendBeneficiaryUnlockTime(address _beneficiary, uint256 _newUnlockTimestamp)
        external
        onlyOwner
        whenNotPaused
        beneficiaryExists(_beneficiary)
    {
        require(_newUnlockTimestamp > beneficiaries[_beneficiary].unlockTimestamp, "TLW: New unlock timestamp must be later than current");
        
        uint256 oldUnlockTimestamp = beneficiaries[_beneficiary].unlockTimestamp;
        beneficiaries[_beneficiary].unlockTimestamp = _newUnlockTimestamp;
        emit UnlockTimeExtended(_beneficiary, oldUnlockTimestamp, _newUnlockTimestamp);
    }

    /**
     * @notice Deactivates a beneficiary, making their locked funds available to the owner (if not withdrawn).
     * @param _beneficiary The address of the beneficiary to remove.
     */
    function removeBeneficiary(address _beneficiary)
        external
        onlyOwner
        whenNotPaused
        beneficiaryExists(_beneficiary)
    {
        Beneficiary storage b = beneficiaries[_beneficiary];
        uint256 remainingLockedAmount = b.amountLocked - b.withdrawnAmount;

        b.isActive = false;
        b.amountLocked = 0; // Clear remaining balance for safety
        b.unlockTimestamp = 0;
        b.withdrawnAmount = 0;

        totalLockedFunds -= remainingLockedAmount;
        beneficiaryCount--;
        emit BeneficiaryRemoved(_beneficiary, remainingLockedAmount);
    }

    /**
     * @notice Allows the owner to withdraw any unallocated funds from the contract.
     * @dev Unallocated funds are contract balance minus totalLockedFunds.
     */
    function emergencyWithdrawOwnerFunds() external onlyOwner whenNotPaused {
        uint256 availableOwnerFunds = address(this).balance - totalLockedFunds;
        require(availableOwnerFunds > 0, "TLW: No unallocated funds available for owner withdrawal");
        
        (bool success, ) = owner().call{value: availableOwnerFunds}("");
        require(success, "TLW: Owner withdrawal failed");
        
        emit OwnerFundsWithdrawn(owner(), availableOwnerFunds);
    }

    /**
     * @notice Pauses the contract. Only owner can call.
     * @dev No funds can be deposited, added to beneficiaries, updated, or withdrawn while paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract. Only owner can call.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // =============================================================
    //                     Beneficiary Functions
    // =============================================================

    /**
     * @notice Allows a beneficiary to withdraw their allocated funds after the unlock timestamp.
     * @dev Withdraws the full remaining amount.
     */
    function withdrawFunds() external payable whenNotPaused beneficiaryExists(msg.sender) {
        Beneficiary storage b = beneficiaries[msg.sender];
