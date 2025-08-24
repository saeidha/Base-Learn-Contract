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
    // A mapping from loan IDs to Loan structs.
    mapping(uint256 => Loan) public loans;
    // A counter to ensure unique loan IDs.
    uint256 public loanCounter;

    // Events to log significant actions.
    event LoanRequested(uint256 indexed id, address indexed borrower, uint256 amount, uint256 interest);
    event LoanFunded(uint256 indexed id, address indexed lender, uint256 amount);
    event LoanRepaid(uint256 indexed id, uint256 totalAmount);
