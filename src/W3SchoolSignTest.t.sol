// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {W3SchoolSign} from "../src/W3SchoolSign.sol";

contract W3SchoolSignTest is Test {
    W3SchoolSign public w3s;

    // Declare addresses for actors in the tests
    address public constant OWNER = address(0x1);
    address public constant ADMIN = address(0x2);
    address public constant USER_1 = address(0x3);
    address public constant USER_2 = address(0x4);

    uint256 public constant COURSE_FEE = 0.1 ether;

    /**
     * @dev This function is run before each test. It's the equivalent of `beforeEach`.
     */
    function setUp() public {
        // Start a prank to set msg.sender to OWNER for deployment
        vm.prank(OWNER);
        w3s = new W3SchoolSign();

        // Grant the ADMIN address admin privileges for tests that need it.
        vm.prank(OWNER);
        w3s.addAdmin(ADMIN);

