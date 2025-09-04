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

    function test_02_Fail_CreateAuction_InvalidDuration() public {
        vm.prank(seller);
        vm.expectRevert(EnglishAuction.InvalidDuration.selector);
        auction.createAuction(address(mockNft), NFT_ID, STARTING_BID, 0);
    }

    // --- Test Start Auction ---
    function test_03_StartAuction_Success() public {
        vm.prank(seller);
        auction.createAuction(address(mockNft), NFT_ID, STARTING_BID, DURATION);
        vm.prank(seller);
        auction.startAuction();
        assertEq(uint(auction.getAuctionState()), uint(EnglishAuction.AuctionState.STARTED));
        assertEq(mockNft.ownerOf(NFT_ID), address(auction));
    }

    function test_04_Fail_StartAuction_NotSeller() public {
        vm.prank(seller);
        auction.createAuction(address(mockNft), NFT_ID, STARTING_BID, DURATION);
        vm.prank(randomUser);
        vm.expectRevert(EnglishAuction.OnlySeller.selector);
        auction.startAuction();
    }
    
    // --- Test Bidding Logic ---
    function test_05_Bid_FirstBid_Success() public {
        vm.prank(seller);
        auction.createAuction(address(mockNft), NFT_ID, STARTING_BID, DURATION);
        vm.prank(seller);
        auction.startAuction();
        
        vm.deal(bidder1, 2 ether);
        vm.prank(bidder1);
        auction.bid{value: STARTING_BID}();
        
        assertEq(auction.getHighestBid(), STARTING_BID);
        assertEq(auction.getHighestBidder(), bidder1);
    }

    function test_06_Fail_Bid_TooLow() public {
        vm.prank(seller);
        auction.createAuction(address(mockNft), NFT_ID, STARTING_BID, DURATION);
        vm.prank(seller);
        auction.startAuction();
        
        vm.deal(bidder1, 1 ether);
        vm.prank(bidder1);
        vm.expectRevert(EnglishAuction.BidTooLow.selector);
        auction.bid{value: STARTING_BID - 1}();
    }
    
    function test_07_Bid_Outbid_Success() public {
        vm.prank(seller);
        auction.createAuction(address(mockNft), NFT_ID, STARTING_BID, DURATION);
        vm.prank(seller);
        auction.startAuction();

        vm.deal(bidder1, 2 ether);
        vm.prank(bidder1);
        auction.bid{value: STARTING_BID}();
        
        uint256 newBid = STARTING_BID + (STARTING_BID / 20) + 1;
        vm.deal(bidder2, 3 ether);
        vm.prank(bidder2);
        auction.bid{value: newBid}();

        assertEq(auction.getHighestBid(), newBid);
        assertEq(auction.getHighestBidder(), bidder2);
        assertEq(auction.getPendingWithdrawal(bidder1), STARTING_BID);
    }

    // --- Test Withdrawals ---
    function test_08_Withdraw_Success() public {
        test_07_Bid_Outbid_Success(); // Setup the outbid scenario

        uint256 bidder1InitialBalance = bidder1.balance;
        vm.prank(bidder1);
        auction.withdraw();
        assertEq(bidder1.balance, bidder1InitialBalance + STARTING_BID);
        assertEq(auction.getPendingWithdrawal(bidder1), 0);
    }
    
    function test_09_Fail_Withdraw_NoFunds() public {
        vm.prank(randomUser);
        vm.expectRevert(EnglishAuction.NoFundsToWithdraw.selector);
        auction.withdraw();
    }
    
    // --- Test End Auction ---
    function test_10_EndAuction_Success() public {
        test_07_Bid_Outbid_Success(); // Setup with bidder2 as highest

        vm.warp(block.timestamp + DURATION + 1);

        uint256 sellerInitialBalance = seller.balance;
        uint256 winningBid = auction.getHighestBid();
        
        vm.prank(randomUser); // Anyone can end the auction
        auction.endAuction();
        
        assertEq(uint(auction.getAuctionState()), uint(EnglishAuction.AuctionState.ENDED));
        assertEq(mockNft.ownerOf(NFT_ID), bidder2);
        assertEq(seller.balance, sellerInitialBalance + winningBid);
    }

    function test_11_Fail_EndAuction_InProgress() public {
        vm.prank(seller);
        auction.createAuction(address(mockNft), NFT_ID, STARTING_BID, DURATION);
        vm.prank(seller);
        auction.startAuction();
        
        vm.expectRevert(EnglishAuction.AuctionInProgress.selector);
        auction.endAuction();
    }

    function test_12_EndAuction_NoBids() public {
        vm.prank(seller);
        auction.createAuction(address(mockNft), NFT_ID, STARTING_BID, DURATION);
        vm.prank(seller);
