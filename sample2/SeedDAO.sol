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
     * @notice Creates a new governance proposal.
     * @param targets The target addresses for the proposal's transactions.
     * @param values The ETH values to be sent in each transaction.
     * @param calldatas The calldata for each transaction.
     * @param description A human-readable description of the proposal.
     */
    function propose(
        address[] memory targets,
        uint[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint) {
        require(governanceToken.getPastVotes(msg.sender, block.number - 1) >= proposalThreshold, "DAO: Proposer does not meet proposal threshold");
        require(targets.length == values.length && targets.length == calldatas.length, "DAO: Proposal arrays must have same length");
        require(targets.length > 0, "DAO: Must provide at least one action");

        proposalCount++;
        uint id = proposalCount;
        
        uint start = block.number + votingDelay;
        uint end = start + votingPeriod;

        Proposal storage newProposal = proposals[id];
        newProposal.id = id;
        newProposal.proposer = msg.sender;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.calldatas = calldatas;
        newProposal.description = description;
        newProposal.creationBlock = block.number;
        newProposal.startBlock = start;
        newProposal.endBlock = end;

        emit ProposalCreated(id, msg.sender, targets, values, calldatas, start, end, description);
        return id;
    }
    
    /**
     * @notice Casts a vote on an active proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support The type of vote (0=Against, 1=For, 2=Abstain).
     */
    function castVote(uint proposalId, uint8 support) external {
        _castVote(msg.sender, proposalId, support, "");
    }

    function castVoteWithReason(uint proposalId, uint8 support, string calldata reason) external {
        _castVote(msg.sender, proposalId, support, reason);
    }

    function _castVote(address voter, uint proposalId, uint8 support, string memory reason) internal {
        Proposal storage p = proposals[proposalId];
        require(state(proposalId) == ProposalState.Active, "DAO: Voting is not active");
        require(p.receipts[voter].hasVoted == false, "DAO: Voter has already voted");
        require(support <= 2, "DAO: Invalid vote type");

        uint96 votes = uint96(governanceToken.getPastVotes(voter, p.startBlock));
        p.receipts[voter] = Receipt({hasVoted: true, support: support, votes: votes});

        if (support == uint8(VoteType.For)) {
            p.forVotes += votes;
        } else if (support == uint8(VoteType.Against)) {
            p.againstVotes += votes;
        } else {
            p.abstainVotes += votes;
        }

        emit VoteCast(voter, proposalId, support, votes, reason);
    }

    /**
     * @notice Executes a succeeded proposal after its timelock has passed.
     * @param proposalId The ID of the proposal to execute.
     */
    function execute(uint proposalId) external payable {
        Proposal storage p = proposals[proposalId];
        require(state(proposalId) == ProposalState.Queued, "DAO: Proposal is not queued for execution");
        require(block.timestamp >= p.executionEta, "DAO: Timelock still active");
        
        p.executed = true;

        for (uint i = 0; i < p.targets.length; i++) {
            (bool success, ) = p.targets[i].call{value: p.values[i]}(p.calldatas[i]);
            require(success, "DAO: Transaction execution failed");
