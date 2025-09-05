// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DAO
 * @dev A Decentralized Autonomous Organization with token-based governance, a treasury,
 * and a full proposal lifecycle including a timelock.
 */
contract DAO is Ownable {
    
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }
    enum VoteType { Against, For, Abstain }

    struct Proposal {
        uint id;
        address proposer;
        address[] targets;
        uint[] values;
        bytes[] calldatas;
        string description;
        uint creationBlock;
        uint startBlock;
        uint endBlock;
        uint executionEta;
        uint forVotes;
        uint againstVotes;
        uint abstainVotes;
        bool executed;
        bool canceled;
        mapping(address => Receipt) receipts;
    }

    struct Receipt {
        bool hasVoted;
        uint8 support; // 0 = Against, 1 = For, 2 = Abstain
        uint96 votes;
    }
    
    IERC20 public immutable governanceToken;

    // Governance Parameters
    uint public votingDelay; // in blocks
    uint public votingPeriod; // in blocks
    uint public proposalThreshold; // min tokens to create proposal
    uint public quorumPercentage; // min % of total supply to vote
    uint public executionDelay; // timelock in seconds

    mapping(uint => Proposal) public proposals;
    uint public proposalCount;

    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, bytes[] calldatas, uint startBlock, uint endBlock, string description);
    event VoteCast(address indexed voter, uint proposalId, uint8 support, uint votes, string reason);
    event ProposalCanceled(uint id);
    event ProposalExecuted(uint id);
    event GovernanceParametersUpdated();
    
    constructor(
        address _tokenAddress,
        uint _votingDelay,
        uint _votingPeriod,
        uint _proposalThreshold,
        uint _quorumPercentage,
        uint _executionDelay
    ) Ownable(msg.sender) {
        governanceToken = IERC20(_tokenAddress);
        setVotingDelay(_votingDelay);
        setVotingPeriod(_votingPeriod);
        setProposalThreshold(_proposalThreshold);
        setQuorumPercentage(_quorumPercentage);
        setExecutionDelay(_executionDelay);
    }

    /**
