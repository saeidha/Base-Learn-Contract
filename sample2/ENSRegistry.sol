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

    /**
     * @dev Sets the resolver for a node.
     * @param node The node to update.
     * @param _resolver The address of the resolver.
     */
    function setResolver(bytes32 node, address _resolver) external whenNotPaused authorised(node) {
        records[node].resolver = _resolver;
        emit NewResolver(node, _resolver);
    }

    /**
     * @dev Returns the resolver for a node.
     * @param node The node to query.
     * @return The address of the resolver.
     */
    function resolver(bytes32 node) external view returns (address) {
        return records[node].resolver;
    }

    /**
     * @dev Sets the TTL for a node.
     * @param node The node to update.
     * @param _ttl The new TTL value.
     */
    function setTTL(bytes32 node, uint64 _ttl) external whenNotPaused authorised(node) {
        records[node].ttl = _ttl;
        emit NewTTL(node, _ttl);
    }

    /**
     * @dev Returns the TTL for a node.
     * @param node The node to query.
     * @return The TTL of the node.
     */
    function ttl(bytes32 node) external view returns (uint64) {
        return records[node].ttl;
    }

    /**
     * @dev Checks if a node exists (i.e., has an owner).
     * @param node The node to check.
     * @return True if the node exists, false otherwise.
     */
    function exists(bytes32 node) external view returns (bool) {
        return records[node].owner != address(0);
    }

    /**
     * @dev Sets or unsets the approval of a given operator.
     * @param operator The operator to set the approval for.
     * @param _approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address operator, bool _approved) external {
        operators[msg.sender][operator] = _approved;
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param _owner The owner to check.
     * @param operator The operator to check.
     * @return True if the operator is approved, false otherwise.
     */
    function isApprovedForAll(address _owner, address operator) external view returns (bool) {
        return operators[_owner][operator];
    }
    
    /**
     * @dev Approves another address to transfer the ownership of a specific node.
     */
    function approve(address to, bytes32 node) external whenNotPaused authorised(node) {
        approved[node] = to;
        emit Approval(node, records[node].owner, to, true);
    }

    /**
     * @dev Gets the approved address for a single node.
     */
    function getApproved(bytes32 node) external view returns (address) {
        return approved[node];
    }

    /**
     * @dev Transfers ownership of a node to another address.
     */
    function transferFrom(address from, address to, bytes32 node) external whenNotPaused {
        require(from == records[node].owner, "ENSRegistry: Not owner");
        require(
            msg.sender == from || 
            operators[from][msg.sender] || 
            approved[node] == msg.sender,
            "ENSRegistry: Not approved for transfer"
        );
        
        // Clear approval after transfer
        approved[node] = address(0);
        _setOwner(node, to);
        emit Transfer(node, to);
    }
    
    /**
     * @dev A convenience function to set all records for a node at once.
     */
    function setRecord(bytes32 node, address _owner, address _resolver, uint64 _ttl) external whenNotPaused authorised(node) {
        _setOwner(node, _owner);
        records[node].resolver = _resolver;
        records[node].ttl = _ttl;
        emit Transfer(node, _owner);
        emit NewResolver(node, _resolver);
        emit NewTTL(node, _ttl);
    }
    
    /**
     * @dev A convenience function to set all records for a subnode at once.
     */
    function setSubnodeRecord(bytes32 node, bytes32 label, address _owner, address _resolver, uint64 _ttl) external whenNotPaused authorised(node) {
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        _setOwner(subnode, _owner);
        records[subnode].resolver = _resolver;
        records[subnode].ttl = _ttl;
