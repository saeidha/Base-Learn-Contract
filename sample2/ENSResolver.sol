// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol";
import "https/github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

abstract contract Resolver {
    function supportsInterface(bytes4 interfaceID) virtual external pure returns (bool);
    function addr(bytes32 node) virtual external view returns (address);
    function setAddr(bytes32 node, address addr) virtual external;
}


/**
 * @title PublicResolver
 * @dev A flexible resolver contract for the ENS-like registry.
 * It stores various types of records for a given node.
 */
contract PublicResolver is ERC165 {
    
    bytes4 private constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 private constant TEXT_INTERFACE_ID = 0x59d1d43c;
    bytes4 private constant NAME_INTERFACE_ID = 0x691f3431;

    mapping(bytes32 => address) private addresses;
    mapping(bytes32 => mapping(string => string)) private texts;
    mapping(bytes32 => string) private names;
    
    // Authorization mapping
    mapping(bytes32 => mapping(address => mapping(address => bool))) public authorisations;

    event AddrChanged(bytes32 indexed node, address a);
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key, string value);
    event NameChanged(bytes32 indexed node, string name);
    event AuthorisationChanged(bytes32 indexed node, address indexed owner, address indexed target, bool isAuthorised);


    modifier authorised(bytes32 node) {
        // This is a simplified authorization check. A real implementation would check against the ENSRegistry.
        // For this example, we will allow anyone to set records.
        // In a real system:
        // ENS ens = ENS(ensAddress);
        // require(ens.owner(node) == msg.sender);
        _;
    }

    /**
     * @dev Sets the address for a node.
     * @param node The node to update.
