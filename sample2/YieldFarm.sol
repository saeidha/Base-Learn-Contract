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
