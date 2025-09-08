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
