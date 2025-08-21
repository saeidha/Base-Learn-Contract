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

  // --- Structs ---
    struct Lock {
        address owner;
        uint256 amount;
        uint256 unlockTime;
        bool active; // To mark if the lock has been withdrawn
    }

        // --- State Variables ---
    IERC20 public immutable lockToken;
    Lock[] public locks;

     mapping(address => uint256[]) public userLockIds;
    mapping(address => uint256) public userTotalLockedAmount;
    uint256 public totalLocked;

    // --- Constructor ---
    constructor(address _tokenAddress) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        lockToken = IERC20(_tokenAddress);
    }

    // --- Core User Functions ---

    /**
     * @notice Locks a specified amount of tokens for a given duration.
     * @dev The user must first approve this contract to spend their tokens.
     * @param _amount The amount of tokens to lock.
     * @param _duration The lock duration in seconds.
     */

     function lock(uint256 _amount, uint256 _duration) external whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        require(_duration > 0, "Duration must be greater than zero");
