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

 /**
     * @dev Requests a new loan.
     * @param _amount The principal amount of the loan.
     * @param _interest The interest rate in basis points (e.g., 500 for 5%).
     * @param _duration The duration of the loan in seconds.
     */
    function requestLoan(uint256 _amount, uint256 _interest, uint256 _duration) public {
        require(_amount > 0, "Loan amount must be greater than zero");
        require(_interest > 0, "Interest rate must be greater than zero");
        require(_duration > 0, "Loan duration must be greater than zero");

        loanCounter++;
        loans[loanCounter] = Loan({
            id: loanCounter,
            borrower: payable(msg.sender),
            lender: payable(address(0)),
            amount: _amount,
            interest: _interest,
            duration: _duration,
            startTime: 0,
            funded: false,
            repaid: false
        });

        emit LoanRequested(loanCounter, msg.sender, _amount, _interest);
    }

    /**
     * @dev Funds an existing loan request.
     * @param _id The ID of the loan to fund.
     */

    function fundLoan(uint256 _id) public payable {
        Loan storage loan = loans[_id];
        
        require(loan.id != 0, "Loan does not exist");
        require(!loan.funded, "Loan is already funded");
        require(msg.value == loan.amount, "Incorrect funding amount sent");
        require(msg.sender != loan.borrower, "Cannot fund your own loan");


        loan.lender = payable(msg.sender);
        loan.funded = true;
        loan.startTime = block.timestamp;

        emit LoanFunded(_id, msg.sender, loan.amount);
        }

    /**
     * @dev Repays a funded loan.
     * @param _id The ID of the loan to repay.
     */
    function repayLoan(uint256 _id) public payable {
        Loan storage loan = loans[_id];
        require(loan.funded, "Loan is not funded");