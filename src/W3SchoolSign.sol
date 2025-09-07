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
    mapping(address => mapping(uint => bool)) public completions;
    mapping(address => bool) public admins;

    uint public courseCounter;

    // =============================================================
    //                             Events
    // =============================================================

    event UserRegistered(address indexed user, string name);
    event UserProfileUpdated(address indexed user, string newName);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event CourseAdded(uint indexed courseId, string name, uint fee);
    event CourseUpdated(uint indexed courseId, string name, string description, uint fee);
    event CourseStatusChanged(uint indexed courseId, bool isActive);
    event UserEnrolled(address indexed user, uint indexed courseId);
    event CourseCompleted(address indexed user, uint indexed courseId);
    event FundsWithdrawn(address indexed owner, uint amount);

    // =============================================================
    //                            Modifiers
    // =============================================================

    modifier onlyAdmin() {
        require(admins[msg.sender], "W3SS: Caller is not an admin");
        _;
    }

    modifier courseExists(uint _courseId) {
        require(_courseId > 0 && _courseId <= courseCounter, "W3SS: Course does not exist");
        _;
    }
    
    // =============================================================
    //                    Admin Management Functions
    // =============================================================

    /**
     * @notice Adds a new admin. Only the owner can call this.
     * @param _admin The address to grant admin privileges to.
     */
    function addAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "W3SS: Invalid admin address");
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    /**
     * @notice Removes an admin. Only the owner can call this.
     * @param _admin The address to revoke admin privileges from.
     */
    function removeAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    // =============================================================
    //                     User Management Functions
    // =============================================================
    
    /**
     * @notice Registers a new user on the platform.
     * @param _name The user's chosen name.
     */
    function registerUser(string memory _name) external {
