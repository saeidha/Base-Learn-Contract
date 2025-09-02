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
     */
    constructor(address _token) Ownable(msg.sender) {
        require(_token != address(0), "TokenVesting: Token address cannot be zero");
        token = IERC20(_token);
    }

    /**
     * @notice Creates a new vesting schedule for a single beneficiary.
     * @param _beneficiary The address of the beneficiary.
     * @param _totalAmount The total amount of tokens to be vested.
     * @param _startTime The start time of the vesting period (Unix timestamp).
     * @param _duration The duration of the vesting period in seconds.
     * @param _cliffDuration The duration of the cliff period in seconds.
     */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _totalAmount,
        uint64 _startTime,
        uint64 _duration,
        uint64 _cliffDuration
