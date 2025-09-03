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
