// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DAO} from "../contracts/DAO.sol";

// Mock ERC20Votes token
contract MockGovToken is Test {
    string public name = "Mock Governance Token";
    string public symbol = "MGT";
    uint8 public decimals = 18;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => Checkpoint[]) public checkpoints;
    struct Checkpoint { uint32 fromBlock; uint96 votes; }

    function mint(address to, uint amount) public {
        balanceOf[to] += amount;
        totalSupply += amount;
        _writeCheckpoint(to, _add, amount);
    }
    function delegate(address delegatee) public { /* Simplified for testing */ }
    function getPastVotes(address account, uint blockNumber) public view returns (uint) {
        uint nCheckpoints = checkpoints[account].length;
        if (nCheckpoints == 0 || checkpoints[account][0].fromBlock > blockNumber) return 0;
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) return checkpoints[account][nCheckpoints - 1].votes;
        
        uint lower = 0; uint upper = nCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2;
            if (checkpoints[account][center].fromBlock > blockNumber) upper = center - 1; else lower = center;
        }
        return checkpoints[account][lower].votes;
    }
    function _writeCheckpoint(address account, function(uint,uint) pure returns(uint) op, uint delta) internal {
        uint nCheckpoints = checkpoints[account].length;
        uint96 oldVotes = nCheckpoints > 0 ? checkpoints[account][nCheckpoints-1].votes : 0;
        uint96 newVotes = uint96(op(oldVotes, delta));
        if (nCheckpoints > 0 && checkpoints[account][nCheckpoints - 1].fromBlock == block.number) {
            checkpoints[account][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[account].push(Checkpoint({fromBlock: uint32(block.number), votes: newVotes}));
        }
    }
    function _add(uint a, uint b) internal pure returns (uint) { return a + b; }
}

// Mock target for proposals
contract Target is Test {
    uint public x;
    event Executed(uint val);
    function execute(uint val) public payable { x = val; emit Executed(val); }
    receive() external payable {}
}

contract TestDAO is Test {
    DAO public dao;
    MockGovToken public token;
    Target public target;
    
    address public owner = address(0x1);
    address public proposer = address(0x2);
    address public voterA = address(0x3);
    address public voterB = address(0x4);
    address public voterC = address(0x5);

    uint constant VOTING_DELAY = 10;
    uint constant VOTING_PERIOD = 100;
    uint constant PROPOSAL_THRESHOLD = 100e18;
    uint constant QUORUM_PERCENTAGE = 10; // 10%
    uint constant EXECUTION_DELAY = 3 days;

    function setUp() public {
        vm.startPrank(owner);
        token = new MockGovToken();
        dao = new DAO(address(token), VOTING_DELAY, VOTING_PERIOD, PROPOSAL_THRESHOLD, QUORUM_PERCENTAGE, EXECUTION_DELAY);
        target = new Target();
        
        token.mint(proposer, 150e18);
        token.mint(voterA, 300e18);
        token.mint(voterB, 500e18);
        token.mint(voterC, 50e18); // Does not meet proposal threshold
        
        vm.deal(address(dao), 100 ether); // Fund treasury
        vm.stopPrank();
    }
    
    // --- Test Proposal Creation ---
    function test_01_Propose_Success() public {
        vm.prank(proposer);
        uint proposalId = dao.propose(getTargets(), getValues(), getCalldatas(), "Proposal 1");
        assertEq(proposalId, 1);
        assertEq(uint(dao.state(proposalId)), uint(DAO.ProposalState.Pending));
    }

    function test_02_Fail_Propose_BelowThreshold() public {
        vm.prank(voterC);
        vm.expectRevert("DAO: Proposer does not meet proposal threshold");
        dao.propose(getTargets(), getValues(), getCalldatas(), "Proposal Fail");
    }

    // --- Test Voting ---
    function test_03_CastVote_Success() public {
        test_01_Propose_Success();
        vm.roll(block.number + VOTING_DELAY + 1);
        
        vm.prank(voterA);
        dao.castVote(1, uint8(DAO.VoteType.For));
        assertTrue(dao.hasVoted(1, voterA));
    }
    
    function test_04_Fail_Vote_NotActive_Pending() public {
        test_01_Propose_Success();
        vm.prank(voterA);
        vm.expectRevert("DAO: Voting is not active");
        dao.castVote(1, 1);
    }
    
    function test_05_Fail_Vote_NotActive_Ended() public {
        test_03_CastVote_Success();
        vm.roll(block.number + VOTING_PERIOD + 1);
        vm.prank(voterB);
        vm.expectRevert("DAO: Voting is not active");
        dao.castVote(1, 1);
    }

    function test_06_Fail_Vote_DoubleVote() public {
        test_03_CastVote_Success();
        vm.prank(voterA);
        vm.expectRevert("DAO: Voter has already voted");
        dao.castVote(1, 0);
    }
    
    // --- Test Proposal Outcome ---
    function test_07_State_Succeeded() public {
        test_01_Propose_Success();
        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voterA); dao.castVote(1, 1); // 300 For
        vm.prank(voterB); dao.castVote(1, 1); // 500 For
        vm.prank(proposer); dao.castVote(1, 0); // 150 Against
        
        vm.roll(block.number + VOTING_PERIOD + 1);
        assertEq(uint(dao.state(1)), uint(DAO.ProposalState.Succeeded));
    }

    function test_08_State_Defeated_Quorum() public {
        test_01_Propose_Success();
        vm.roll(block.number + VOTING_DELAY + 1);
        vm.prank(proposer); dao.castVote(1, 1);
        
        vm.roll(block.number + VOTING_PERIOD + 1);
        assertEq(uint(dao.state(1)), uint(DAO.ProposalState.Defeated));
    }

    function test_09_State_Defeated_Votes() public {
        test_01_Propose_Success();
        vm.roll(block.number + VOTING_DELAY + 1);
        
        vm.prank(voterA); dao.castVote(1, 0); // 300 Against
        vm.prank(voterB); dao.castVote(1, 0); // 500 Against
        vm.prank(proposer); dao.castVote(1, 1); // 150 For

        vm.roll(block.number + VOTING_PERIOD + 1);
        assertEq(uint(dao.state(1)), uint(DAO.ProposalState.Defeated));
    }

    // --- Test Execution ---
    function test_10_Execute_Success() public {
        test_07_State_Succeeded();
        
        vm.prank(randomUser); dao.queue(1);
        assertEq(uint(dao.state(1)), uint(DAO.ProposalState.Queued));
        
        vm.warp(block.timestamp + EXECUTION_DELAY + 1);
        
        uint targetInitialBalance = address(target).balance;
        dao.execute(1);
        
