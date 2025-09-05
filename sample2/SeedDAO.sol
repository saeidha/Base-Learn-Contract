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
