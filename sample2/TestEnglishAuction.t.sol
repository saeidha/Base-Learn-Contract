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
    address public bidder1 = address(0x2);
    address public bidder2 = address(0x3);
    address public randomUser = address(0x4);

    uint256 constant NFT_ID = 1;
    uint256 constant STARTING_BID = 1 ether;
    uint256 constant DURATION = 7 days;

    function setUp() public {
        auction = new EnglishAuction();
        mockNft = new MockNFT();

        // Mint NFT to seller
        vm.prank(seller);
        mockNft.mint(seller, NFT_ID);

        // Seller approves the auction contract
        vm.prank(seller);
        mockNft.approve(address(auction), NFT_ID);
    }

    // --- Test Create Auction ---
    function test_01_CreateAuction_Success() public {
        vm.prank(seller);
        auction.createAuction(address(mockNft), NFT_ID, STARTING_BID, DURATION);
        assertEq(uint(auction.getAuctionState()), uint(EnglishAuction.AuctionState.CREATED));
        assertEq(auction.getSeller(), seller);
    }
