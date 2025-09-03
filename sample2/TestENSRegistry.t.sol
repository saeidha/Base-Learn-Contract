// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../contracts/ENSRegistry.sol";
import "../contracts/PublicResolver.sol";

contract TestENSRegistry is Test {
    ENSRegistry registry;
    PublicResolver resolver;
    
    address owner = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);
    
    bytes32 testNode = keccak256("test");
    bytes32 testLabel = keccak256("label");
    bytes32 testSubNode = keccak256(abi.encodePacked(testNode, testLabel));

    function setUp() public {
        vm.prank(owner);
        registry = new ENSRegistry();
        
        vm.prank(owner);
        resolver = new PublicResolver();
        
        vm.startPrank(owner);
        registry.register(testNode, user1);
        registry.setResolver(testNode, address(resolver));
        vm.stopPrank();
    }
    
    function test_initialOwner() public {
        assertEq(registry.owner(testNode), user1);
    }
    
    function test_setOwner() public {
        vm.prank(user1);
        registry.setOwner(testNode, user2);
        assertEq(registry.owner(testNode), user2);
    }
