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
