// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/StakeAndLoan.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// A mock ERC20 token for testing purposes.
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract StakeAndLoanTest is Test {
    StakeAndLoan public stakeAndLoan;
    MockERC20 public collateralToken;
    MockERC20 public loanToken;

    address public user = address(1);
    address public liquidator = address(2);

    /**
     * @dev Sets up the test environment.
     */
    function setUp() public {
        collateralToken = new MockERC20("Collateral", "COL");
        loanToken = new MockERC20("Loan Token", "LOAN");
        stakeAndLoan = new StakeAndLoan(address(collateralToken), address(loanToken));
        // Mint tokens for the user and the contract (to be loaned out)
        collateralToken.mint(user, 100 ether);
        loanToken.mint(address(stakeAndLoan), 50000 ether);
    }

    /**
     * @dev Tests staking functionality.
     */
    function testStake() public {
        vm.startPrank(user);
        collateralToken.approve(address(stakeAndLoan), 10 ether);
        stakeAndLoan.stake(10 ether);
        assertEq(stakeAndLoan.getUserStakedBalance(user), 10 ether);
        vm.stopPrank();
    }

    /**
     * @dev Tests borrowing functionality.
     */
    function testBorrow() public {
        // First, stake some collateral
        vm.startPrank(user);
        collateralToken.approve(address(stakeAndLoan), 10 ether);
        stakeAndLoan.stake(10 ether);

        // Now, borrow against it
        uint256 maxBorrowable = stakeAndLoan.getAccountMaxBorrowableValue(user);
        stakeAndLoan.borrow(maxBorrowable);
        
        assertEq(loanToken.balanceOf(user), maxBorrowable);
        (uint256 principal, , ) = stakeAndLoan.getLoanDetails(user);
        assertEq(principal, maxBorrowable);
        vm.stopPrank();
    }

    /**
     * @dev Tests loan repayment functionality.
     */
    function testRepay() public {
        // Stake and borrow
        vm.startPrank(user);
        collateralToken.approve(address(stakeAndLoan), 10 ether);
        stakeAndLoan.stake(10 ether);
        stakeAndLoan.borrow(1000 ether);

        // Advance time to accrue interest
        vm.warp(block.timestamp + 365 days);

        uint256 totalOwed = stakeAndLoan.getLoanValue(user);
        loanToken.mint(user, totalOwed); // Mint enough to repay
        loanToken.approve(address(stakeAndLoan), totalOwed);

        stakeAndLoan.repay();
        (uint256 principal, , ) = stakeAndLoan.getLoanDetails(user);
        assertEq(principal, 0);
        assertEq(loanToken.balanceOf(user), 0);
        vm.stopPrank();
    }

      /**
     * @dev Tests unstaking functionality.
     */
    function testUnstake() public {
        // Stake, borrow, and repay
        vm.startPrank(user);
        collateralToken.approve(address(stakeAndLoan), 10 ether);
        stakeAndLoan.stake(10 ether);
        stakeAndLoan.borrow(1000 ether);