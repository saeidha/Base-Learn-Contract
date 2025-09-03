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
    event ControllerChanged(address indexed controller, bool enabled);
    event NodeBurnt(bytes32 indexed node);


    modifier authorised(bytes32 node) {
        address owner = records[node].owner;
        require(owner == msg.sender || operators[owner][msg.sender] || controllers[msg.sender], "ENSRegistry: Not authorised");
        _;
    }

    constructor() {
        // The root node is owned by the contract deployer initially.
        records[0x0].owner = msg.sender;
    }

    /**
     * @dev Registers a new node with an owner. Only callable by contract owner for top-level domains.
     * @param node The hash of the name to register.
     * @param _owner The address of the new owner.
     */
    function register(bytes32 node, address _owner) external onlyOwner {
        _setOwner(node, _owner);
        emit Transfer(node, _owner);
    }
    
    /**
     * @dev Returns the owner of a node.
     * @param node The node to query.
     * @return The address of the owner.
     */
    function owner(bytes32 node) external view returns (address) {
        return records[node].owner;
    }

    /**
     * @dev Sets the owner of a node.
     * @param node The node to update.
     * @param _owner The address of the new owner.
     */
    function setOwner(bytes32 node, address _owner) external whenNotPaused authorised(node) {
        _setOwner(node, _owner);
        emit Transfer(node, _owner);
    }

    /**
     * @dev Sets the owner of a subnode.
     * @param node The parent node.
     * @param label The label of the subnode.
     * @param _owner The address of the new owner of the subnode.
     */
    function setSubnodeOwner(bytes32 node, bytes32 label, address _owner) external whenNotPaused authorised(node) {
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        _setOwner(subnode, _owner);
        emit NewOwner(node, label, _owner);
    }
