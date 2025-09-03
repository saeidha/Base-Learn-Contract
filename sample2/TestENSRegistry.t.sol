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
    
    function test_fail_setOwnerNotAuthorized() public {
        vm.prank(user2);
        registry.setOwner(testNode, user2);
    }

    function test_setSubnodeOwner() public {
        vm.prank(user1);
        registry.setSubnodeOwner(testNode, testLabel, user2);
        assertEq(registry.owner(testSubNode), user2);
    }
    
    function test_setResolver() public {
        address newResolver = address(0x4);
        vm.prank(user1);
        registry.setResolver(testNode, newResolver);
        assertEq(registry.resolver(testNode), newResolver);
    }
    
    function test_setTTL() public {
        uint64 newTtl = 3600;
        vm.prank(user1);
        registry.setTTL(testNode, newTtl);
        assertEq(registry.ttl(testNode), newTtl);
    }
    
    function test_exists() public {
        assertTrue(registry.exists(testNode));
        assertFalse(registry.exists(keccak256("nonexistent")));
    }
    
    function test_setApprovalForAll() public {
        vm.prank(user1);
        registry.setApprovalForAll(user2, true);
        assertTrue(registry.isApprovedForAll(user1, user2));
    }

    function test_transferFrom() public {
        vm.prank(user1);
        registry.transferFrom(user1, user2, testNode);
        assertEq(registry.owner(testNode), user2);
    }
    
    function test_transferFromByOperator() public {
        vm.prank(user1);
        registry.setApprovalForAll(user2, true);
        
        vm.prank(user2);
        registry.transferFrom(user1, user2, testNode);
        assertEq(registry.owner(testNode), user2);
    }
    
    function test_approveAndTransfer() public {
        vm.prank(user1);
        registry.approve(user2, testNode);
        assertEq(registry.getApproved(testNode), user2);

        vm.prank(user2);
        registry.transferFrom(user1, user2, testNode);
        assertEq(registry.owner(testNode), user2);
        assertEq(registry.getApproved(testNode), address(0));
    }

    function test_setRecord() public {
        vm.prank(user1);
        registry.setRecord(testNode, user2, address(resolver), 7200);
        assertEq(registry.owner(testNode), user2);
        assertEq(registry.resolver(testNode), address(resolver));
        assertEq(registry.ttl(testNode), 7200);
    }

    function test_setSubnodeRecord() public {
        vm.prank(user1);
        registry.setSubnodeRecord(testNode, testLabel, user2, address(resolver), 1800);
        assertEq(registry.owner(testSubNode), user2);
        assertEq(registry.resolver(testSubNode), address(resolver));
        assertEq(registry.ttl(testSubNode), 1800);
    }
    
    function test_renounceOwnership() public {
        vm.prank(user1);
        registry.renounceOwnership(testNode);
        assertEq(registry.owner(testNode), address(0));
    }

    function test_controller() public {
        vm.prank(owner);
        registry.setController(user2, true);
        assertTrue(registry.isController(user2));

        vm.prank(user2); // As a controller
        registry.setOwner(testNode, user2);
        assertEq(registry.owner(testNode), user2);
    }
    
