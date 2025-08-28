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
        yieldFarm = new YieldFarm(address(stakingToken), address(rewardToken), APY_NONE, APY_30_DAYS);
        // Mint some tokens for testing
        stakingToken.mint(user1, 1000 ether);
        rewardToken.mint(address(yieldFarm), 10000 ether);