// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/StakeAndLoan.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// A mock ERC20 token for testing purposes.
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract StakeAndLoanTest is Test {
    StakeAndLoan public stakeAndLoan;
    MockERC20 public collateralToken;
    MockERC20 public loanToken;

    address public user = address(1);
    address public liquidator = address(2);

    /**
     * @dev Sets up the test environment.
     */
    function setUp() public {
        collateralToken = new MockERC20("Collateral", "COL");
