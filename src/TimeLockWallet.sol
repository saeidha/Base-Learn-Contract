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
