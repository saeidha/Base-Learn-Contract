// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
/**
 * @title LockToken
 * @author Gemini
 * @notice A contract for time-locking a specific ERC20 token.
 * Users can lock tokens for a chosen duration and withdraw them only after the lock expires.
 */

contract LockToken is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- Events ---
    event TokensLocked(address indexed user, uint256 lockId, uint256 amount, uint256 unlockTime);
    event TokensWithdrawn(address indexed user, uint256 lockId, uint256 amount);
    event LockExtended(uint256 indexed lockId, uint256 newUnlockTime);
    event EmergencyWithdrawal(address indexed token, address indexed to, uint256 amount);
