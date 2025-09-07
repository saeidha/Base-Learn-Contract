// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title W3SchoolSign
 * @dev A smart contract to manage user registrations and course enrollments for a decentralized learning platform.
 * Users "sign up" for the platform and then "sign" into courses by enrolling.
 */
contract W3SchoolSign is Ownable {

    // =============================================================
    //                           Structs
    // =============================================================

    struct User {
        string name;
        bool isRegistered;
        uint[] enrolledCourseIds;
    }

    struct Course {
        string name;
        string description;
        uint enrollmentFee;
        bool isActive;
        uint enrollmentCount;
    }

    // =============================================================
    //                         State Variables
    // =============================================================

    mapping(address => User) public users;
    mapping(uint => Course) public courses;
    mapping(address => mapping(uint => bool)) public enrollments;
