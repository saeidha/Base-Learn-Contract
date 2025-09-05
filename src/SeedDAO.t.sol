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
