// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {EnglishAuction} from "../contracts/EnglishAuction.sol";

// Mock ERC721 for testing
contract MockNFT is Test {
    function mint(address to, uint256 tokenId) public {
        vm.prank(to);
