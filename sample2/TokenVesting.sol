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
    ) external onlyOwner {
        require(_beneficiary != address(0), "TokenVesting: Beneficiary address cannot be zero");
        require(vestingSchedules[_beneficiary].totalAmount == 0, "TokenVesting: Beneficiary already has a vesting schedule");
        require(_totalAmount > 0, "TokenVesting: Total amount must be greater than zero");
        require(_duration > 0, "TokenVesting: Duration must be greater than zero");
        require(_cliffDuration <= _duration, "TokenVesting: Cliff duration cannot be longer than total duration");
        require(_startTime >= block.timestamp, "TokenVesting: Start time must be in the future");

        vestingSchedules[_beneficiary] = VestingSchedule({
            beneficiary: _beneficiary,
            startTime: _startTime,
            duration: _duration,
            cliffDuration: _cliffDuration,
            totalAmount: _totalAmount,
            releasedAmount: 0
        });

        beneficiaries.push(_beneficiary);

        emit VestingScheduleCreated(_beneficiary, _totalAmount, _startTime, _duration, _cliffDuration);
    }
    
    /**
     * @notice Creates vesting schedules for multiple beneficiaries at once.
     * @param _beneficiaries An array of beneficiary addresses.
     * @param _amounts An array of total token amounts for each beneficiary.
     * @param _startTimes An array of start times for each beneficiary.
     * @param _durations An array of durations for each beneficiary.
     * @param _cliffDurations An array of cliff durations for each beneficiary.
     */
    function createMultipleVestingSchedules(
        address[] calldata _beneficiaries,
        uint256[] calldata _amounts,
        uint64[] calldata _startTimes,
        uint64[] calldata _durations,
        uint64[] calldata _cliffDurations
    ) external onlyOwner {
        require(_beneficiaries.length == _amounts.length, "Arrays length mismatch");
        require(_beneficiaries.length == _startTimes.length, "Arrays length mismatch");
        require(_beneficiaries.length == _durations.length, "Arrays length mismatch");
        require(_beneficiaries.length == _cliffDurations.length, "Arrays length mismatch");

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            createVestingSchedule(_beneficiaries[i], _amounts[i], _startTimes[i], _durations[i], _cliffDurations[i]);
        }
    }


    /**
     * @notice Allows a beneficiary to release their vested tokens.
     */
    function release() external nonReentrant {
