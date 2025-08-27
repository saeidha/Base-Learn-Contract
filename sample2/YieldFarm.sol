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
