// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Test} from "forge-std/Test.sol";
import {TokenVesting} from "../contracts/TokenVesting.sol";

// Mock ERC20 token for testing purposes
contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

contract TestTokenVesting is Test {
    TokenVesting public tokenVesting;
    MockToken public mockToken;

    address public owner;
    address public beneficiary1;
    address public beneficiary2;
    address public randomUser;

    uint256 constant TOTAL_SUPPLY = 1_000_000e18;
    uint256 constant VESTING_AMOUNT_1 = 100_000e18;
    uint256 constant VESTING_AMOUNT_2 = 50_000e18;

    uint64 public startTime;
    uint64 constant DURATION = 365 days;
    uint64 constant CLIFF = 180 days;

    function setUp() public {
        owner = makeAddr("owner");
        beneficiary1 = makeAddr("beneficiary1");
        beneficiary2 = makeAddr("beneficiary2");
        randomUser = makeAddr("randomUser");

        vm.prank(owner);
        mockToken = new MockToken("Mock Token", "MTK", TOTAL_SUPPLY);

        vm.prank(owner);
        tokenVesting = new TokenVesting(address(mockToken));

        // Transfer tokens to the vesting contract
        vm.prank(owner);
        mockToken.transfer(address(tokenVesting), VESTING_AMOUNT_1 + VESTING_AMOUNT_2);

        startTime = uint64(block.timestamp + 1 days); // Vesting starts tomorrow
    }

    function test_01_ContractDeployment() public {
        assertEq(address(tokenVesting.token()), address(mockToken));
        assertEq(tokenVesting.owner(), owner);
    }

    function test_02_CreateVestingSchedule_Success() public {
        vm.prank(owner);
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, CLIFF);

        TokenVesting.VestingSchedule memory schedule = tokenVesting.getVestingSchedule(beneficiary1);
        assertEq(schedule.beneficiary, beneficiary1);
        assertEq(schedule.totalAmount, VESTING_AMOUNT_1);
        assertEq(schedule.startTime, startTime);
        assertEq(schedule.duration, DURATION);
        assertEq(schedule.cliffDuration, CLIFF);
        assertEq(schedule.releasedAmount, 0);
        assertEq(tokenVesting.getBeneficiaryCount(), 1);
        assertEq(tokenVesting.getBeneficiaryAtIndex(0), beneficiary1);
    }
    
    function test_03_Fail_CreateVestingSchedule_NotOwner() public {
        vm.prank(randomUser);
        vm.expectRevert();
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, CLIFF);
    }
    
    function test_04_Fail_CreateVestingSchedule_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("TokenVesting: Beneficiary address cannot be zero");
        tokenVesting.createVestingSchedule(address(0), VESTING_AMOUNT_1, startTime, DURATION, CLIFF);
    }
    
    function test_05_Fail_CreateVestingSchedule_AlreadyExists() public {
        vm.prank(owner);
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, CLIFF);
        
        vm.prank(owner);
        vm.expectRevert("TokenVesting: Beneficiary already has a vesting schedule");
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, CLIFF);
    }
