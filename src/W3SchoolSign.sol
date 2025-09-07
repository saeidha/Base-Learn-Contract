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
    }

    /**
     * @notice Updates the enrollment fee for a course.
     */
    function updateCourseFee(uint _courseId, uint _newFee) external onlyAdmin courseExists(_courseId) {
        Course storage course = courses[_courseId];
        course.enrollmentFee = _newFee;
        emit CourseUpdated(_courseId, course.name, course.description, course.enrollmentFee);
    }

    /**
     * @notice Toggles the active status of a course. Inactive courses cannot be enrolled in.
     */
    function toggleCourseActiveStatus(uint _courseId) external onlyAdmin courseExists(_courseId) {
        Course storage course = courses[_courseId];
        course.isActive = !course.isActive;
        emit CourseStatusChanged(_courseId, course.isActive);
    }

    /**
     * @notice Marks a user as having completed a course.
     */
    function markCourseCompleted(address _user, uint _courseId) external onlyAdmin courseExists(_courseId) {
        require(enrollments[_user][_courseId], "W3SS: User not enrolled in this course");
        require(!completions[_user][_courseId], "W3SS: Course already marked as completed");
        
        completions[_user][_courseId] = true;
        emit CourseCompleted(_user, _courseId);
    }
    
    // =============================================================
    //                    Enrollment Functions
    // =============================================================

    /**
     * @notice Allows a registered user to enroll in a course by sending the required fee.
     * @param _courseId The ID of the course to enroll in.
     */
    function enroll(uint _courseId) external payable courseExists(_courseId) {
        require(users[msg.sender].isRegistered, "W3SS: User not registered");
        Course storage course = courses[_courseId];
        require(course.isActive, "W3SS: Course is not active");
        require(msg.value == course.enrollmentFee, "W3SS: Incorrect enrollment fee sent");
        require(!enrollments[msg.sender][_courseId], "W3SS: Already enrolled in this course");

        enrollments[msg.sender][_courseId] = true;
        course.enrollmentCount++;
        users[msg.sender].enrolledCourseIds.push(_courseId);

        emit UserEnrolled(msg.sender, _courseId);
    }

    // =============================================================
    //                   Financial Functions (Owner Only)
    // =============================================================
    
    /**
     * @notice Allows the owner to withdraw the entire balance of the contract.
     */
    function withdrawFunds() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "W3SS: No funds to withdraw");
        
        (bool success, ) = owner().call{value: balance}("");
        require(success, "W3SS: Withdrawal failed");
        
        emit FundsWithdrawn(owner(), balance);
    }

    // =============================================================
    //                        View Functions
    // =============================================================

    function isUserRegistered(address _user) external view returns (bool) {
        return users[_user].isRegistered;
    }

    function getUserName(address _user) external view returns (string memory) {
        return users[_user].name;
    }

    function isUserAdmin(address _user) external view returns (bool) {
        return admins[_user];
    }

    function getTotalCourses() external view returns (uint) {
        return courseCounter;
    }
    
    function getCourseDetails(uint _courseId) external view courseExists(_courseId) returns (string memory, string memory, uint, bool, uint) {
        Course memory course = courses[_courseId];
        return (course.name, course.description, course.enrollmentFee, course.isActive, course.enrollmentCount);
    }

    function getCourseFee(uint _courseId) external view courseExists(_courseId) returns (uint) {
        return courses[_courseId].enrollmentFee;
    }

    function isCourseActive(uint _courseId) external view courseExists(_courseId) returns (bool) {
        return courses[_courseId].isActive;
    }

    function isEnrolled(address _user, uint _courseId) external view returns (bool) {
        return enrollments[_user][_courseId];
    }

    function hasCompletedCourse(address _user, uint _courseId) external view returns (bool) {
        return completions[_user][_courseId];
    }

    function getUserEnrolledCourses(address _user) external view returns (uint[] memory) {
        return users[_user].enrolledCourseIds;
    }

    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title W3SchoolSign
 * @dev A smart contract to manage user registrations and course enrollments for a decentralized learning platform.
