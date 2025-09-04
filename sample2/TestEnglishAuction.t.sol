// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {EnglishAuction} from "../contracts/EnglishAuction.sol";

// Mock ERC721 for testing
contract MockNFT is Test {
    function mint(address to, uint256 tokenId) public {
        vm.prank(to);
        ERC721(address(this))._mint(to, tokenId);
    }
    function approve(address to, uint256 tokenId) public {
        ERC721(address(this))._approve(to, tokenId);
    }
    function ownerOf(uint256 tokenId) public view returns (address) {
        return ERC721(address(this)).ownerOf(tokenId);
    }
}

contract TestEnglishAuction is Test {
    EnglishAuction public auction;
    MockNFT public mockNft;

    address public seller = address(0x1);
