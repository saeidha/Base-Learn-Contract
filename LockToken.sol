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
        uint256 lockId = locks.length;
        uint256 unlockTime = block.timestamp + _duration;
        locks.push(Lock({ owner: msg.sender, amount: _amount, unlockTime: unlockTime, active: true })); 
        userLockIds[msg.sender].push(lockId); 
        userTotalLockedAmount[msg.sender] += _amount; 
        totalLocked += _amount; 
        emit TokensLocked(msg.sender, lockId, _amount, unlockTime);

        lockToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

     /**
     * @notice Withdraws the tokens from a specific lock after it has expired.
     * @param _lockId The ID of the lock to withdraw from.
     */
    function withdraw(uint256 _lockId) external whenNotPaused {
        Lock storage userLock = locks[_lockId];
          require(userLock.owner == msg.sender, "Not lock owner");
        require(userLock.active, "Lock already withdrawn");
        require(block.timestamp >= userLock.unlockTime, "Lock period not over yet");
 uint256 amount = userLock.amount;
        
        // Effects
        userLock.active = false;
        userTotalLockedAmount[msg.sender] -= amount;
        totalLocked -= amount;
emit TokensWithdrawn(msg.sender, _lockId, amount);

        // Interactions
        lockToken.safeTransfer(msg.sender, amount);
    }
    /**
     * @notice Extends the duration of an existing, active lock.
     * @param _lockId The ID of the lock to extend.
     * @param _extraDuration The additional time in seconds to add to the lock.
     */
    function extendLock(uint256 _lockId, uint256 _extraDuration) external {
        Lock storage userLock = locks[_lockId];
         require(userLock.owner == msg.sender, "Not lock owner");
        require(userLock.active, "Lock not active");
        require(_extraDuration > 0, "Extra duration must be positive");

         userLock.unlockTime += _extraDuration;

        emit LockExtended(_lockId, userLock.unlockTime);
    }
    // --- View Functions ---

    /**
     * @notice Gets the details of a specific lock.
     * @param _lockId The ID of the lock.
     * @return The lock details: owner, amount, unlockTime, and active status.
     */
        function getLockDetails(uint256 _lockId) external view returns (address, uint256, uint256, bool) {
            Lock memory userLock = locks[_lockId];
        return (userLock.owner, userLock.amount, userLock.unlockTime, userLock.active);
    }

    /**
     * @notice Gets all lock IDs for a given user.
     * @param _user The address of the user.
     * @return An array of lock IDs owned by the user.
     */
        function getLocksForUser(address _user) external view returns (uint256[] memory) {
            return userLockIds[_user];
    }
    
    /**
     * @notice Returns the total number of locks created.
     */
        function getLockCount() external view returns (uint256) {
        return locks.length;
    }

    // --- Admin Functions ---

    /**
     * @notice Pauses the contract, preventing new locks and withdrawals.
     * @dev Can only be called by the owner.
     */

    function pause() external onlyOwner {
        _pause();
    }
    /**
     * @notice Unpauses the contract, re-enabling functionality.
     * @dev Can only be called by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    /**
     * @notice Allows the owner to withdraw any ERC20 tokens accidentally sent to this contract.
     * @dev This is a safety measure. It cannot withdraw the designated `lockToken`.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     * @param _amount The amount to withdraw.
     */
    function withdrawStuckTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        require(_tokenAddress != address(lockToken), "Cannot withdraw the main lock token");
        IERC20 stuckToken = IERC20(_tokenAddress);
        uint256 balance = stuckToken.balanceOf(address(this));
        require(_amount <= balance, "Insufficient balance");
