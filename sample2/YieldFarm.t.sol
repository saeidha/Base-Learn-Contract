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
     address public owner;
    address public user1 = address(1);
    
    uint256 constant APY_NONE = 500; // 5%
    uint256 constant APY_30_DAYS = 750; // 7.5%

 /**
     * @dev Sets up the test environment before each test.
     */
    function setUp() public {
        owner = address(this);
        stakingToken = new MockERC20("Staking Token", "STK");
        rewardToken = new MockERC20("Reward Token", "RWD");
        yieldFarm = new YieldFarm(address(stakingToken), address(rewardToken));

        // Set up reward rates
        yieldFarm.setRewardRate(YieldFarm.LockupTier.None, APY_NONE);
        yieldFarm.setRewardRate(YieldFarm.LockupTier.ThirtyDays, APY_30_DAYS);

        // Fund user and the farm contract
        stakingToken.mint(user1, 1000 ether);
        rewardToken.mint(address(yieldFarm), 10000 ether);
    }

    /**
     * @dev Tests staking with no lockup.
     */
    function testStakeNoLockup() public {
        vm.startPrank(user1);
        stakingToken.approve(address(yieldFarm), 100 ether);
        yieldFarm.stake(100 ether, YieldFarm.LockupTier.None);
        
        YieldFarm.StakeInfo memory info = yieldFarm.getStakeInfo(user1);
        assertEq(info.amount, 100 ether);
        assertEq(uint(info.lockupTier), uint(YieldFarm.LockupTier.None));
        vm.stopPrank();
    }
    
    /**
     * @dev Tests staking with a 30-day lockup.
     */
    function testStakeWithLockup() public {
        vm.startPrank(user1);
        stakingToken.approve(address(yieldFarm), 100 ether);
        yieldFarm.stake(100 ether, YieldFarm.LockupTier.ThirtyDays);
        
        assertTrue(yieldFarm.isLockupActive(user1));
        vm.stopPrank();
    }

    /**
     * @dev Tests that unstaking is blocked during the lockup period.
     */
    function testFailUnstakeDuringLockup() public {
        stakingToken.approve(address(yieldFarm), 100 ether);
        yieldFarm.stake(100 ether, YieldFarm.LockupTier.ThirtyDays);
        
        vm.expectRevert("Lockup period is still active");
        yieldFarm.unstake(50 ether);
        vm.stopPrank();
    }

    /**
     * @dev Tests successful unstaking after the lockup period has ended.
     */
    function testUnstakeAfterLockup() public {
        