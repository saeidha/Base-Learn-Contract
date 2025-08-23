// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LockToken} from "../src/LockToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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