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
    struct Loan {
        uint256 principal;
        uint256 interestRate; // Annual interest rate in basis points (e.g., 500 = 5%)
        uint256 startTime;
    }
    // Mapping from user address to their loan details.
    mapping(address => Loan) public userLoan;
    // The percentage of collateral value that can be borrowed (e.g., 7500 = 75%).
    uint256 public collateralizationRatio = 7500; // In basis points

    // Price of collateral token in terms of loan token (e.g., 1 ETH = 2000 DAI).
    // In a real-world scenario, this would be fed by an oracle.
    uint256 public collateralPrice = 2000;

    // --- Events ---

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Liquidated(address indexed user, uint256 collateralLiquidated);

    // --- Constructor ---

    /**
     * @dev Sets up the contract with the addresses of collateral and loan tokens.
     * @param _collateralTokenAddress The address of the ERC20 token used as collateral.
     * @param _loanTokenAddress The address of the ERC20 token to be loaned out.
     */