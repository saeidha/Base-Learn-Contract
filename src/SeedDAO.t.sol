// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DAO} from "../contracts/DAO.sol";

// Mock ERC20Votes token
contract MockGovToken is Test {
    string public name = "Mock Governance Token";
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
