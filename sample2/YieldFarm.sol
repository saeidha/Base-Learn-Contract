// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title YieldFarm
 * @dev A contract for staking tokens to earn rewards with optional time-locks for higher APY.
 */
contract YieldFarm is Ownable, ReentrancyGuard {
        // --- State Variables ---

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    uint256 public totalStaked;

    // Enum for different lockup tiers
    enum LockupTier {
        None,       // Tier 0
        ThirtyDays, // Tier 1
        NinetyDays  // Tier 2
    }


    // Struct to store user's staking information
    struct StakeInfo {
        uint256 amount;
        uint256 since; // Timestamp of last action (stake or claim)
        LockupTier lockupTier;
        uint256 lockupEndTime;
    }

    mapping(address => StakeInfo) public stakes;

    // Mapping from LockupTier to its reward rate (APY in basis points, e.g., 500 = 5%)
    mapping(LockupTier => uint256) public rewardRates;

    // --- Events ---

    event Staked(address indexed user, uint256 amount, LockupTier tier);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardRateSet(LockupTier tier, uint256 rate);

// --- Constructor ---

    constructor(address _stakingTokenAddress, address _rewardTokenAddress) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingTokenAddress);
        rewardToken = IERC20(_rewardTokenAddress);
    }

    // --- Core Staking Functions ---

/**
     * @dev Stakes tokens. If user already has a stake, it adds to it.
     * @param _amount The amount of stakingToken to stake.
     * @param _tier The lockup tier to use for the stake.
     */
    function stake(uint256 _amount, LockupTier _tier) public nonReentrant {
        require(_amount > 0, "Cannot stake 0");
        
        StakeInfo storage userStake = stakes[msg.sender];

// If user has an existing stake, claim pending rewards first
        if (userStake.amount > 0) {
            uint256 pending = calculateRewards(msg.sender);
            if (pending > 0) {
                rewardToken.transfer(msg.sender, pending);
                emit RewardsClaimed(msg.sender, pending);
            }
            // A user must stick to their initial lockup tier
            require(_tier == userStake.lockupTier, "Cannot change lockup tier");
        } else {
            userStake.lockupTier = _tier;
            if (_tier == LockupTier.ThirtyDays) {
                userStake.lockupEndTime = block.timestamp + 30 days;
            } else if (_tier == LockupTier.NinetyDays) {
                userStake.lockupEndTime = block.timestamp + 90 days;
            }
        }

        userStake.amount += _amount;
        userStake.since = block.timestamp;
        totalStaked += _amount;

        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        emit Staked(msg.sender, _amount, _tier);
    }

    /**
     * @dev Unstakes tokens and claims any pending rewards.
     * @param _amount The amount to unstake.
     */
    function unstake(uint256 _amount) public nonReentrant {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount >= _amount, "Insufficient staked amount");
        require(isLockupActive(msg.sender) == false, "Lockup period is still active");
        
         uint256 pending = calculateRewards(msg.sender);
        
        userStake.amount -= _amount;
        userStake.since = block.timestamp;
        totalStaked -= _amount;

        // Transfer rewards and staked tokens
        if (pending > 0) {
            rewardToken.transfer(msg.sender, pending);
            emit RewardsClaimed(msg.sender, pending);
        }
        stakingToken.transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount);
    }

    /**
     * @dev Claims pending rewards without unstaking.
     */
    function claimRewards() public nonReentrant {
        uint256 pending = calculateRewards(msg.sender);
        require(pending > 0, "No rewards to claim");

        stakes[msg.sender].since = block.timestamp;
        rewardToken.transfer(msg.sender, pending);
        emit RewardsClaimed(msg.sender, pending);
    }
    // --- View Functions ---

    /**
     * @dev Calculates pending rewards for a user.
     * @param _user The address of the user.
     * @return The amount of rewardToken owed.
     */
    function calculateRewards(address _user) public view returns (uint256) {
        StakeInfo memory userStake = stakes[_user];
        if (userStake.amount == 0) {
            return 0;
        }
        uint256 rate = rewardRates[userStake.lockupTier];
        uint256 timeElapsed = block.timestamp - userStake.since;
        
        // Formula: (amount * APY * time) / (basis_points * seconds_in_year)
        return (userStake.amount * rate * timeElapsed) / (10000 * 365 days);
    }

    /**
     * @dev Checks if a user's lockup period is currently active.
     * @param _user The address of the user.
     * @return True if the lockup is active, false otherwise.
     */
    function isLockupActive(address _user) public view returns (bool) {
        return block.timestamp < stakes[_user].lockupEndTime;
    }

    /**
     * @dev Returns the full staking information for a user.
     * @param _user The address of the user.
     * @return A StakeInfo struct.
     */
    function getStakeInfo(address _user) public view returns (StakeInfo memory) {
        return stakes[_user];
    }