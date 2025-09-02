// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TokenVesting
 * @dev A smart contract for managing token vesting schedules for multiple beneficiaries.
 * It allows for linear vesting with an optional cliff period.
 * The owner can create vesting schedules, and beneficiaries can release their vested tokens.
 */
contract TokenVesting is Ownable, ReentrancyGuard {

