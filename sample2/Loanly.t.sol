// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Loanly.sol";
contract LoanlyTest is Test {
    Loanly public loanly;
    address public borrower = address(1);
    address public lender = address(2);
    uint256 public constant LOAN_AMOUNT = 1 ether;
    uint256 public constant INTEREST_RATE = 500; // 5%
    uint256 public constant DURATION = 30 days;

    /**
     * @dev Sets up the testing environment before each test.
     */
    function setUp() public {
        loanly = new Loanly();
        vm.deal(borrower, 10 ether);
        vm.deal(lender, 10 ether);
    }

    /**
     * @dev Tests the loan request functionality.
     */
    function testRequestLoan() public {
        vm.prank(borrower);
        loanly.requestLoan(LOAN_AMOUNT, INTEREST_RATE, DURATION);

        (uint256 id, address b, , uint256 amount, uint256 interest, , , bool funded, bool repaid) = loanly.getLoanDetails(1);
        assertEq(id, 1);
        assertEq(b, borrower);
        assertEq(amount, LOAN_AMOUNT);
        assertEq(interest, INTEREST_RATE);
        assertFalse(funded);
        assertFalse(repaid);
    }

    /**
     * @dev Tests the loan funding functionality.
     */
    function testFundLoan() public {
        vm.prank(borrower);
        loanly.requestLoan(LOAN_AMOUNT, INTEREST_RATE, DURATION);

        vm.prank(lender);
        loanly.fundLoan{value: LOAN_AMOUNT}(1);

        ( , , address l, , , , , bool funded, ) = loanly.getLoanDetails(1);
        assertEq(l, lender);
        assertTrue(funded);
    }
    /**
     * @dev Tests the loan repayment functionality.
     */
    function testRepayLoan() public {
        vm.prank(borrower);
        loanly.requestLoan(LOAN_AMOUNT, INTEREST_RATE, DURATION);
        vm.prank(lender);
        loanly.fundLoan{value: LOAN_AMOUNT}(1);
        // Advance time to simulate interest accrual
        vm.warp(block.timestamp + DURATION);

        uint256 interest = loanly.calculateInterest(1);
        uint256 totalRepayment = LOAN_AMOUNT + interest;
        uint256 lenderInitialBalance = lender.balance;

        vm.prank(borrower);
        loanly.repayLoan{value: totalRepayment}(1);
        assertTrue(loanly.isLoanRepaid(1));
        assertEq(lender.balance, lenderInitialBalance + totalRepayment);
    }

    /**
     * @dev Tests the withdrawal functionality.
     */

    function testWithdraw() public {
        vm.prank(borrower);
        loanly.requestLoan(LOAN_AMOUNT, INTEREST_RATE, DURATION);
        vm.prank(lender);
        loanly.fundLoan{value: LOAN_AMOUNT}(1);
        vm.warp(block.timestamp + DURATION);
        uint256 interest = loanly.calculateInterest(1);
        uint256 totalRepayment = LOAN_AMOUNT + interest;
        vm.prank(borrower);
        loanly.repayLoan{value: totalRepayment}(1);
        uint256 lenderInitialBalance = lender.balance;
        vm.prank(lender);
        loanly.withdraw(1);
        assertTrue(lender.balance > lenderInitialBalance);
    }

    /**
     * @dev Tests failure case for funding own loan.
     */
    function testFailFundOwnLoan() public {
        vm.prank(borrower);
        loanly.requestLoan(LOAN_AMOUNT, INTEREST_RATE, DURATION);
        vm.prank(borrower);
        vm.expectRevert("Cannot fund your own loan");
        loanly.fundLoan{value: LOAN_AMOUNT}(1);
    }

    /**
     * @dev Tests failure case for incorrect repayment amount.
     */
    function testFailIncorrectRepayment() public {
        vm.prank(borrower);
        loanly.requestLoan(LOAN_AMOUNT, INTEREST_RATE, DURATION);

        vm.prank(lender);
        loanly.fundLoan{value: LOAN_AMOUNT}(1);
        vm.prank(borrower);
        vm.expectRevert("Incorrect repayment amount");
        loanly.repayLoan{value: 1 wei}(1);
    }

    /**
     * @dev Tests the interest calculation.
     */
    function testCalculateInterest() public {
        vm.prank(borrower);
        loanly.requestLoan(LOAN_AMOUNT, INTEREST_RATE, DURATION);
        vm.prank(lender);
        loanly.fundLoan{value: LOAN_AMOUNT}(1);
        vm.warp(block.timestamp + DURATION);

        uint256 expectedInterest = (LOAN_AMOUNT * INTEREST_RATE) / 10000;
        uint256 calculatedInterest = loanly.calculateInterest(1);
        assertEq(calculatedInterest, expectedInterest);
    }
    /**
     * @dev Tests getting the current time.
     */
    function testGetCurrentTime() public {
        uint256 currentTime = loanly.getCurrentTime();
        assertTrue(currentTime > 0);
    }
    /**
     * @dev Tests checking if a loan is funded.
     */
    function testIsLoanFunded() public {
        vm.prank(borrower);
        loanly.requestLoan(LOAN_AMOUNT, INTEREST_RATE, DURATION);
        assertFalse(loanly.isLoanFunded(1));
