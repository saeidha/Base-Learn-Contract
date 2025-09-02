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
    
    function test_06_ReleaseTokens_BeforeCliff() public {
        vm.prank(owner);
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, CLIFF);
        
        vm.warp(startTime + CLIFF - 1 days);
        
        assertEq(tokenVesting.getReleasableAmount(beneficiary1), 0);

        vm.prank(beneficiary1);
        vm.expectRevert("TokenVesting: No tokens available for release");
        tokenVesting.release();
    }
    
    function test_07_ReleaseTokens_AfterCliff_MidVesting() public {
        vm.prank(owner);
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, CLIFF);
        
        uint64 timeAfterCliff = startTime + CLIFF + 90 days;
        vm.warp(timeAfterCliff);
        
        uint256 expectedVested = (VESTING_AMOUNT_1 * (timeAfterCliff - startTime)) / DURATION;
        assertEq(tokenVesting.getReleasableAmount(beneficiary1), expectedVested);
        
        vm.prank(beneficiary1);
        tokenVesting.release();
        
        assertEq(mockToken.balanceOf(beneficiary1), expectedVested);
        assertEq(tokenVesting.getReleasedAmount(beneficiary1), expectedVested);
    }
    
    function test_08_ReleaseTokens_AfterVestingPeriod() public {
        vm.prank(owner);
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, CLIFF);
        
        vm.warp(startTime + DURATION + 1 days);
        
        assertEq(tokenVesting.getReleasableAmount(beneficiary1), VESTING_AMOUNT_1);
        
        vm.prank(beneficiary1);
        tokenVesting.release();
        
        assertEq(mockToken.balanceOf(beneficiary1), VESTING_AMOUNT_1);
        assertEq(tokenVesting.getReleasedAmount(beneficiary1), VESTING_AMOUNT_1);
    }
    
    function test_09_MultipleReleases() public {
        vm.prank(owner);
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, CLIFF);

        // First release
        uint64 firstReleaseTime = startTime + CLIFF + 30 days;
        vm.warp(firstReleaseTime);
        uint256 firstExpectedVested = (VESTING_AMOUNT_1 * (firstReleaseTime - startTime)) / DURATION;
        vm.prank(beneficiary1);
        tokenVesting.release();
        assertEq(mockToken.balanceOf(beneficiary1), firstExpectedVested);

        // Second release
        uint64 secondReleaseTime = startTime + CLIFF + 90 days;
        vm.warp(secondReleaseTime);
        uint256 totalVested = (VESTING_AMOUNT_1 * (secondReleaseTime - startTime)) / DURATION;
        uint256 secondExpectedVested = totalVested - firstExpectedVested;
        vm.prank(beneficiary1);
        tokenVesting.release();
        assertEq(mockToken.balanceOf(beneficiary1), totalVested);
    }
    
    function test_10_CreateMultipleVestingSchedules() public {
        address[] memory beneficiaries = new address[](2);
        beneficiaries[0] = beneficiary1;
        beneficiaries[1] = beneficiary2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = VESTING_AMOUNT_1;
        amounts[1] = VESTING_AMOUNT_2;
        
        uint64[] memory startTimes = new uint64[](2);
        startTimes[0] = startTime;
        startTimes[1] = startTime;
        
        uint64[] memory durations = new uint64[](2);
        durations[0] = DURATION;
        durations[1] = DURATION;

        uint64[] memory cliffDurations = new uint64[](2);
        cliffDurations[0] = CLIFF;
        cliffDurations[1] = CLIFF;
        
        vm.prank(owner);
        tokenVesting.createMultipleVestingSchedules(beneficiaries, amounts, startTimes, durations, cliffDurations);
        
        assertEq(tokenVesting.getBeneficiaryCount(), 2);
        assertEq(tokenVesting.getTotalAmount(beneficiary1), VESTING_AMOUNT_1);
        assertEq(tokenVesting.getTotalAmount(beneficiary2), VESTING_AMOUNT_2);
    }
    
    function test_11_ViewFunctions() public {
        vm.prank(owner);
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, CLIFF);
        
        assertEq(tokenVesting.getStartTime(beneficiary1), startTime);
        assertEq(tokenVesting.getDuration(beneficiary1), DURATION);
        assertEq(tokenVesting.getCliffDuration(beneficiary1), CLIFF);
        assertEq(tokenVesting.getTotalAmount(beneficiary1), VESTING_AMOUNT_1);
        assertEq(tokenVesting.getReleasedAmount(beneficiary1), 0);
        assertTrue(tokenVesting.hasVestingSchedule(beneficiary1));
        assertFalse(tokenVesting.hasVestingSchedule(beneficiary2));
        assertEq(tokenVesting.getVestingEndTime(beneficiary1), startTime + DURATION);
        assertEq(tokenVesting.getCliffEndTime(beneficiary1), startTime + CLIFF);
        assertEq(tokenVesting.getRemainingAmount(beneficiary1), VESTING_AMOUNT_1);
    }
    
    function test_12_GetVestedAmountAtTimestamp() public {
        vm.prank(owner);
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, CLIFF);

        uint64 futureTime = startTime + CLIFF + 100 days;
        uint256 expectedVested = (VESTING_AMOUNT_1 * (futureTime - startTime)) / DURATION;
        
        assertEq(tokenVesting.getVestedAmountAt(beneficiary1, futureTime), expectedVested);
    }
    
    function test_13_TotalLockedAmount() public {
        assertEq(tokenVesting.getTotalLockedAmount(), VESTING_AMOUNT_1 + VESTING_AMOUNT_2);
    }
    
    function test_14_Release_NoTokensVested() public {
         vm.prank(owner);
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, CLIFF);
        
        vm.warp(startTime - 1 days); // Before vesting starts
        
        vm.prank(beneficiary1);
        vm.expectRevert("TokenVesting: No tokens available for release");
        tokenVesting.release();
    }

    function test_15_Release_AllTokensAlreadyReleased() public {
        vm.prank(owner);
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, CLIFF);
        
        vm.warp(startTime + DURATION + 1 days);
        
        vm.prank(beneficiary1);
        tokenVesting.release();
        
        // Try to release again
        vm.prank(beneficiary1);
        vm.expectRevert("TokenVesting: No tokens available for release");
        tokenVesting.release();
    }
    
    function test_16_Fail_CreateSchedule_PastStartTime() public {
        vm.prank(owner);
        uint64 pastTime = uint64(block.timestamp - 1 days);
        vm.expectRevert("TokenVesting: Start time must be in the future");
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, pastTime, DURATION, CLIFF);
    }

    function test_17_Fail_CreateSchedule_ZeroDuration() public {
        vm.prank(owner);
        vm.expectRevert("TokenVesting: Duration must be greater than zero");
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, 0, CLIFF);
    }
    
    function test_18_Fail_CreateSchedule_CliffLongerThanDuration() public {
        vm.prank(owner);
        vm.expectRevert("TokenVesting: Cliff duration cannot be longer than total duration");
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, DURATION + 1);
    }

    function test_19_GetVestedAmount_NoSchedule() public {
        assertEq(tokenVesting.getVestedAmount(randomUser), 0);
    }

    function test_20_GetReleasableAmount_NoSchedule() public {
        assertEq(tokenVesting.getReleasableAmount(randomUser), 0);
    }

    function test_21_MultipleBeneficiaries_IndependentReleases() public {
        // Schedule for beneficiary 1
        vm.prank(owner);
        tokenVesting.createVestingSchedule(beneficiary1, VESTING_AMOUNT_1, startTime, DURATION, CLIFF);

        // Schedule for beneficiary 2
        vm.prank(owner);
        tokenVesting.createVestingSchedule(beneficiary2, VESTING_AMOUNT_2, startTime, DURATION, CLIFF);

        // Time passes
        uint64 time = startTime + CLIFF + 50 days;
        vm.warp(time);

