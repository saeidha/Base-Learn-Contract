// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title A Decentralized Raffle Contract
 * @author Gemini
 * @notice This contract is for creating a provably fair and decentralized lottery.
 * @dev Implements Chainlink VRFv2 and Chainlink Automation.
 */
contract Raffle is VRFConsumerBaseV2 {
