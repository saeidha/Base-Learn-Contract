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

