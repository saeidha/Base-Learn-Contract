// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/YieldFarm.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


// Mock ERC20 token for testing
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    function mint(address to, uint256 amount) public { _mint(to, amount); }
}

contract YieldFarmTest is Test {
    YieldFarm public yieldFarm;
    MockERC20 public stakingToken;
    MockERC20 public rewardToken;

    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        stakingToken = new MockERC20("Staking Token", "STK");
        rewardToken = new MockERC20("Reward Token", "RWD");
        yieldFarm = new YieldFarm(address(stakingToken), address(rewardToken), 1e18); // 1 RWD per second

        // Mint tokens to users
        stakingToken.mint(user1, 1000e18);
        stakingToken.mint(user2, 1000e18);
        rewardToken.mint(address(yieldFarm), 10000e18); // Fund the yield farm with rewards
    }

    function testStakeAndWithdraw() public {
        vm.startPrank(user1);
        stakingToken.approve(address(yieldFarm), 100e18);
        yieldFarm.stake(100e18);
        assertEq(yieldFarm.stakedBalance(user1), 100e18);

        vm.warp(block.timestamp + 100); // Advance time by 100 seconds
        yieldFarm.withdraw(50e18);
        assertEq(yieldFarm.stakedBalance(user1), 50e18);
        vm.stopPrank();
    }

    function testClaimRewards() public {
        vm.startPrank(user1);
        stakingToken.approve(address(yieldFarm), 100e18);
        yieldFarm.stake(100e18);
        vm.warp(block.timestamp + 100); // Advance time by 100 seconds
        yieldFarm.claimRewards();
        assertEq(rewardToken.balanceOf(user1), 100e18); // Should have earned 100 RWD
        vm.stopPrank();
    }

    function testMultipleUsers() public {
        vm.startPrank(user1);
        stakingToken.approve(address(yieldFarm), 200e18);
        yieldFarm.stake(200e18);
        vm.stopPrank();

        vm.startPrank(user2);
        stakingToken.approve(address(yieldFarm), 300e18);
        yieldFarm.stake(300e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 100); // Advance time by 100 seconds

        vm.startPrank(user1);
        yieldFarm.claimRewards();
        assertEq(rewardToken.balanceOf(user1), 40e18); // 200/(200+300)*100 = 40 RWD
        vm.stopPrank(); 
        vm.startPrank(user2);
        yieldFarm.claimRewards();
        