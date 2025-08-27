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