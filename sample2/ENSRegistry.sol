// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol";

abstract contract ENS {
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) virtual external;
    function setResolver(bytes32 node, address resolver) virtual external;
    function setOwner(bytes32 node, address owner) virtual external;
    function owner(bytes32 node) virtual external view returns (address);
    function resolver(bytes32 node) virtual external view returns (address);
}

/**
 * @title ENSRegistry
 * @dev A contract for a name registration and resolution system, similar to ENS.
 * It allows for the registration of nodes, setting resolvers, and managing ownership.
 */
contract ENSRegistry is Ownable, Pausable, IERC165 {
    
    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32 => Record) private records;
    mapping(address => mapping(address => bool)) private operators;
    mapping(bytes32 => address) private approved;
    mapping(address => bool) private controllers;

    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event Transfer(bytes32 indexed node, address owner);
    event NewResolver(bytes32 indexed node, address resolver);
    event NewTTL(bytes32 indexed node, uint64 ttl);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Approval(bytes32 indexed node, address owner, address approved, bool isApproved);
