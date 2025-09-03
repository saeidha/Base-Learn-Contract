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

