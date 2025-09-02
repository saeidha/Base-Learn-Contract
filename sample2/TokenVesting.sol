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
        address beneficiary = msg.sender;
        uint256 releasableAmount = getReleasableAmount(beneficiary);

        require(releasableAmount > 0, "TokenVesting: No tokens available for release");

        vestingSchedules[beneficiary].releasedAmount += releasableAmount;

        emit TokensReleased(beneficiary, releasableAmount);

        require(token.transfer(beneficiary, releasableAmount), "TokenVesting: Token transfer failed");
    }
    
    // --- View Functions ---

    /**
     * @notice Gets the number of beneficiaries with vesting schedules.
     * @return The total number of beneficiaries.
     */
    function getBeneficiaryCount() public view returns (uint256) {
        return beneficiaries.length;
    }
    
    /**
     * @notice Gets the address of a beneficiary at a specific index.
     * @param _index The index of the beneficiary in the beneficiaries array.
     * @return The address of the beneficiary.
     */
    function getBeneficiaryAtIndex(uint256 _index) public view returns (address) {
        return beneficiaries[_index];
    }

    /**
     * @notice Gets the details of a vesting schedule for a specific beneficiary.
     * @param _beneficiary The address of the beneficiary.
     * @return The VestingSchedule struct for the given beneficiary.
     */
    function getVestingSchedule(address _beneficiary) public view returns (VestingSchedule memory) {
        return vestingSchedules[_beneficiary];
    }
    
    /**
     * @notice Gets the start time of the vesting schedule for a beneficiary.
     */
    function getStartTime(address _beneficiary) public view returns (uint64) {
        return vestingSchedules[_beneficiary].startTime;
    }

    /**
     * @notice Gets the duration of the vesting schedule for a beneficiary.
     */
    function getDuration(address _beneficiary) public view returns (uint64) {
        return vestingSchedules[_beneficiary].duration;
    }

    /**
     * @notice Gets the cliff duration of the vesting schedule for a beneficiary.
     */
    function getCliffDuration(address _beneficiary) public view returns (uint64) {
        return vestingSchedules[_beneficiary].cliffDuration;
    }

    /**
     * @notice Gets the total amount of tokens for a beneficiary's vesting schedule.
     */
    function getTotalAmount(address _beneficiary) public view returns (uint256) {
        return vestingSchedules[_beneficiary].totalAmount;
    }

    /**
     * @notice Gets the amount of tokens already released to a beneficiary.
     */
    function getReleasedAmount(address _beneficiary) public view returns (uint256) {
        return vestingSchedules[_beneficiary].releasedAmount;
    }

    /**
     * @notice Calculates the total amount of vested tokens for a beneficiary at the current time.
     * @param _beneficiary The address of the beneficiary.
     * @return The total vested amount of tokens.
     */
    function getVestedAmount(address _beneficiary) public view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[_beneficiary];
        if (schedule.totalAmount == 0) {
            return 0;
        }
        return _calculateVestedAmount(schedule, uint64(block.timestamp));
    }

    /**
     * @notice Calculates the amount of tokens that can be released by a beneficiary at the current time.
     * @param _beneficiary The address of the beneficiary.
     * @return The amount of releasable tokens.
     */
    function getReleasableAmount(address _beneficiary) public view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[_beneficiary];
        if (schedule.totalAmount == 0) {
            return 0;
        }

        uint256 vestedAmount = _calculateVestedAmount(schedule, uint64(block.timestamp));
        return vestedAmount - schedule.releasedAmount;
    }
    
    /**
     * @notice Calculates the vested amount at a specific timestamp.
     * @param _beneficiary The address of the beneficiary.
     * @param _timestamp The timestamp to calculate the vested amount at.
     * @return The vested amount at the given timestamp.
     */
    function getVestedAmountAt(address _beneficiary, uint64 _timestamp) public view returns (uint256) {
        return _calculateVestedAmount(vestingSchedules[_beneficiary], _timestamp);
    }
    
    /**
     * @notice Checks if a beneficiary has an existing vesting schedule.
     * @param _beneficiary The address of the beneficiary.
