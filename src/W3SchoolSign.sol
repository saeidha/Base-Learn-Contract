// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title W3SchoolSign
 * @dev A smart contract to manage user registrations and course enrollments for a decentralized learning platform.
 * Users "sign up" for the platform and then "sign" into courses by enrolling.
 */
contract W3SchoolSign is Ownable {

