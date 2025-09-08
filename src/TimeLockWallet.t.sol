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
