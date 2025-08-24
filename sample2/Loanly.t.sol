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
