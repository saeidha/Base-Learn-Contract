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

    struct VestingSchedule {
        address beneficiary;
        uint64 startTime;
        uint64 duration;
        uint64 cliffDuration;
        uint256 totalAmount;
        uint256 releasedAmount;
    }

    IERC20 public immutable token;

    // Mapping from beneficiary address to their vesting schedule
    mapping(address => VestingSchedule) private vestingSchedules;
    // Array of all beneficiary addresses to enable iteration
    address[] public beneficiaries;

    event VestingScheduleCreated(address indexed beneficiary, uint256 totalAmount, uint64 startTime, uint64 duration, uint64 cliffDuration);
    event TokensReleased(address indexed beneficiary, uint256 amount);

    /**
     * @dev Sets the ERC20 token contract address.
     * @param _token The address of the ERC20 token to be vested.
