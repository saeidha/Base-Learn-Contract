// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract WeightedVoting is ERC20 {
    mapping(address => bool) claimed;

    uint constant maxSupply = 1000000;

    using EnumerableSet for EnumerableSet.AddressSet;

    struct Issue {
        EnumerableSet.AddressSet voters;
        string issueDesc;
        uint votesFor;
        uint votesAgainst;
        uint votesAbstain;
        uint totalVotes;
        uint quorum;
        bool passed;
        bool closed;
    }

    Issue[] issues;

    enum Votes{ AGAINST, FOR, ABSTAIN }

    error TokensClaimed();
    error AllTokensClaimed();
    error NoTokensHeld();
    error QuorumTooHigh(uint _proposedQuorumAmount);
    error AlreadyVoted();
    error VotingClosed();

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        Issue storage newIssue = issues.push();
        newIssue.issueDesc = "Burnt";
        newIssue.closed = true;
    }

    function claim() public {
        address sender = _msgSender();

        if (claimed[sender]) revert TokensClaimed();
        if (totalSupply() == maxSupply) revert AllTokensClaimed();

        _mint(sender, 100);
        claimed[sender] = true;
    }

    function createIssue(string memory _issueDesc, uint _quorum) external returns(uint) {
        address sender = _msgSender();
        uint balance = balanceOf(sender);

        if (balance == 0) revert NoTokensHeld();
        if (_quorum > totalSupply()) revert QuorumTooHigh(_quorum);
        
        Issue storage newIssue = issues.push();
        newIssue.issueDesc = _issueDesc;
        newIssue.quorum = _quorum;

        return issues.length - 1;
    }

    struct ReturnableIssue {
        address[] voters;
        string issueDesc;
        uint votesFor;
        uint votesAgainst;
        uint votesAbstain;
        uint totalVotes;
        uint quorum;
        bool passed;
        bool closed;
    }

    function getIssue(uint _id) external view returns(ReturnableIssue memory) {
        require(issues.length > _id, "Invalid id");

        Issue storage issue = issues[_id];
        EnumerableSet.AddressSet storage votersSet = issue.voters;

        address[] memory voters = new address[](votersSet.length());
        for (uint i = 0; i < votersSet.length(); i++) {
            voters[i] = votersSet.at(i);
        }

        return ReturnableIssue(
            voters,
            issue.issueDesc,
            issue.votesFor,
            issue.votesAgainst,
            issue.votesAbstain,
            issue.totalVotes,
            issue.quorum,
            issue.passed,
            issue.closed
        );
    }

    function vote(uint _issueId, Votes _vote) public {
        require(issues.length > _issueId, "Invalid issueId");

        address sender = _msgSender();
        uint balance = balanceOf(sender);

        Issue storage issue = issues[_issueId];

        if (issue.closed) revert VotingClosed();
        if (issue.voters.contains(sender)) revert AlreadyVoted();

        issue.voters.add(sender);

        if (_vote == Votes.AGAINST) {
            issue.votesAgainst += balance;
        } else if (_vote == Votes.FOR) {
            issue.votesFor += balance;
        } else if (_vote == Votes.ABSTAIN) {
            issue.votesAbstain += balance;
        }

        issue.totalVotes += balance;

        if (issue.totalVotes >= issue.quorum) {
            issue.closed = true;
            issue.passed = issue.votesFor > issue.votesAgainst;
        }
    }
}