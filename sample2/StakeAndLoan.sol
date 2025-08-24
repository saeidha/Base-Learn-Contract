// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title StakeAndLoan
 * @dev A contract that allows users to stake collateral tokens and borrow loan tokens.
 */
contract StakeAndLoan is Ownable {
    // --- State Variables ---

    IERC20 public immutable collateralToken;
    IERC20 public immutable loanToken;
    // Mapping from user address to their staked collateral balance.
    mapping(address => uint256) public stakedBalance;
    // Struct to hold details of a user's loan.