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

    constructor(
        address _collateralTokenAddress,
        address _loanTokenAddress
    ) Ownable(msg.sender) {
        collateralToken = IERC20(_collateralTokenAddress);
        loanToken = IERC20(_loanTokenAddress);
    }

    // --- Core Functions ---
    /**
     * @dev Stakes collateral tokens into the contract.
     * @param _amount The amount of collateral tokens to stake.
     */
    function stake(uint256 _amount) public {
        require(_amount > 0, "Stake amount must be positive");
        stakedBalance[msg.sender] += _amount;
        require(
            collateralToken.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );
        emit Staked(msg.sender, _amount);
    }

    /**
     * @dev Unstakes collateral tokens from the contract.
     * @param _amount The amount of collateral tokens to unstake.
     */

    function unstake(uint256 _amount) public {
        require(_amount > 0, "Unstake amount must be positive");
        require(
            stakedBalance[msg.sender] >= _amount,
            "Insufficient staked balance"
        );
        uint256 maxBorrowable = getAccountMaxBorrowableValue(msg.sender) -
            getLoanValue(msg.sender);
        require(
            getCollateralValue(stakedBalance[msg.sender] - _amount) >=
                maxBorrowable,
            "Unstaking would make you undercollateralized"
        );
        stakedBalance[msg.sender] -= _amount;
        require(
            collateralToken.transfer(msg.sender, _amount),
            "Token transfer failed"
        );
        emit Unstaked(msg.sender, _amount);
    }

    /**
     * @dev Borrows loan tokens against staked collateral.
     * @param _amount The amount of loan tokens to borrow.
     */

    function borrow(uint256 _amount) public {
        require(_amount > 0, "Borrow amount must be positive");
        require(stakedBalance[msg.sender] > 0, "No collateral staked");
        require(
            userLoan[msg.sender].principal == 0,
            "Loan already exists, repay first"
        );
        uint256 maxBorrowable = getAccountMaxBorrowableValue(msg.sender);
        require(
            _amount <= maxBorrowable,
            "Borrow amount exceeds collateralization ratio"
        );
        userLoan[msg.sender] = Loan({
            principal: _amount,
            interestRate: 500, // 5% annual interest
            startTime: block.timestamp
        });
        require(
            loanToken.transfer(msg.sender, _amount),
            "Loan token transfer failed"
        );
        emit Borrowed(msg.sender, _amount);
    }

    /**
     * @dev Repays an active loan.
     */
    function repay() public {
        Loan storage loan = userLoan[msg.sender];
        require(loan.principal > 0, "No active loan to repay");
        uint256 totalOwed = getLoanValue(msg.sender);
        require(
            loanToken.transferFrom(msg.sender, address(this), totalOwed),
            "Repayment transfer failed"
        );
        delete userLoan[msg.sender];
        emit Repaid(msg.sender, totalOwed);
    }

    /**
     * @dev Liquidates an undercollateralized position.
     * @param _borrower The address of the borrower to liquidate.
     */
    function liquidate(address _borrower) public {
        uint256 collateralValue = getCollateralValue(stakedBalance[_borrower]);
                uint256 loanValue = getLoanValue(_borrower);




}
