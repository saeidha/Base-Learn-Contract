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
        require(!users[msg.sender].isRegistered, "W3SS: User already registered");
        require(bytes(_name).length > 0, "W3SS: Name cannot be empty");
        
        users[msg.sender] = User({
            name: _name,
            isRegistered: true,
            enrolledCourseIds: new uint[](0)
        });
        
        emit UserRegistered(msg.sender, _name);
    }

    /**
     * @notice Allows a registered user to update their name.
     * @param _newName The new name for the user.
     */
    function updateUserName(string memory _newName) external {
        require(users[msg.sender].isRegistered, "W3SS: User not registered");
        require(bytes(_newName).length > 0, "W3SS: Name cannot be empty");
        
        users[msg.sender].name = _newName;
        emit UserProfileUpdated(msg.sender, _newName);
    }

    // =============================================================
    //                   Course Management Functions (Admin Only)
    // =============================================================

    /**
     * @notice Adds a new course to the platform.
     * @param _name The name of the course.
     * @param _description A brief description of the course.
     * @param _fee The enrollment fee in wei.
     */
    function addCourse(string memory _name, string memory _description, uint _fee) external onlyAdmin {
        require(bytes(_name).length > 0, "W3SS: Course name cannot be empty");
        courseCounter++;
        courses[courseCounter] = Course({
            name: _name,
            description: _description,
            enrollmentFee: _fee,
            isActive: true,
            enrollmentCount: 0
        });
        emit CourseAdded(courseCounter, _name, _fee);
    }

    /**
     * @notice Updates the details of an existing course.
     */
    function updateCourseDetails(uint _courseId, string memory _name, string memory _description) external onlyAdmin courseExists(_courseId) {
        require(bytes(_name).length > 0, "W3SS: Course name cannot be empty");
        Course storage course = courses[_courseId];
        course.name = _name;
        course.description = _description;
        emit CourseUpdated(_courseId, course.name, course.description, course.enrollmentFee);
