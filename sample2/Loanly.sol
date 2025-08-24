// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Loanly
 * @dev A simple smart contract for peer-to-peer lending with interest.
 */
contract Loanly {
    // A structure to hold the details of each loan.
    struct Loan {
        uint256 id;
        address payable borrower;
        address payable lender;
        uint256 amount;
        uint256 interest; // Basis points, e.g., 500 for 5%
        uint256 duration; // in seconds
        uint256 startTime;
        bool funded;
        bool repaid;
    }