// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AIBLockedXpToken} from "../src/AIBLockedXpToken.sol";

contract AIBLockedXpTokenTest is Test {
    AIBLockedXpToken public token;
    address public owner = address(0x123);
    address public user1 = address(0x456);
    address public user2 = address(0x789);

    function setUp() public {
        vm.startPrank(owner);
        token = new AIBLockedXpToken(owner);
        vm.stopPrank();
    }

    function test_initial_state() public {
        assertEq(token.name(), "AIBLockedXpToken");
        assertEq(token.symbol(), "AIBLXP");
        assertEq(token.owner(), owner);
        assertEq(token.maxSupply(), 100 * 10 * 10**18);
    }

    function test_add_to_whitelist() public {
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        vm.prank(owner);
        token.addToWhitelist(users);

        assertTrue(token.whitelist(user1));
        assertTrue(token.whitelist(user2));
    }

    function test_claim() public {
        address[] memory users = new address[](1);
        users[0] = user1;

        vm.prank(owner);
        token.addToWhitelist(users);

        vm.prank(user1);
        token.claim();

        assertEq(token.balanceOf(user1), 10 * 10**18);
        assertTrue(token.hasClaimed(user1));
        assertEq(token.totalClaims(), 1);
    }

    function test_claim_not_whitelisted() public {
        vm.prank(user1);
        vm.expectRevert("Not whitelisted");
        token.claim();
    }

    function test_claim_already_claimed() public {
        address[] memory users = new address[](1);
        users[0] = user1;

        vm.prank(owner);
        token.addToWhitelist(users);

        vm.prank(user1);
        token.claim();

        vm.prank(user1);
        vm.expectRevert("Already claimed");
        token.claim();
    }

    function test_max_supply_limit() public {
        // Set max supply to current total supply
        vm.startPrank(owner);
        token.updateMaxSupply(token.totalSupply());
        vm.stopPrank();

        address[] memory newUser = new address[](1);
        newUser[0] = user1;
        vm.prank(owner);
        token.addToWhitelist(newUser);

        vm.prank(user1);
        vm.expectRevert("Max supply reached");
        token.claim();
    }

    function test_non_transferable() public {
        address[] memory users = new address[](1);
        users[0] = user1;

        vm.prank(owner);
        token.addToWhitelist(users);

        vm.prank(user1);
        token.claim();

        vm.prank(user1);
        vm.expectRevert("Token is non-transferable");
        token.transfer(user2, 10 * 10**18);
    }

    function test_update_max_supply() public {
        uint256 newMaxSupply = 200 * 10**18;
        vm.prank(owner);
        token.updateMaxSupply(newMaxSupply);
        assertEq(token.maxSupply(), newMaxSupply);
    }

    function test_update_max_supply_not_owner() public {
        uint256 newMaxSupply = 200 * 10**18;
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("OwnableUnauthorizedAccount(address)")), user1));
        token.updateMaxSupply(newMaxSupply);
    }

    function test_update_max_supply_less_than_total_supply() public {
        address[] memory users = new address[](1);
        users[0] = user1;

        vm.prank(owner);
        token.addToWhitelist(users);

        vm.prank(user1);
        token.claim();

        uint256 newMaxSupply = 5 * 10**18; // Less than total supply
        vm.prank(owner);
        vm.expectRevert("New max supply is less than total supply");
        token.updateMaxSupply(newMaxSupply);
    }
}
