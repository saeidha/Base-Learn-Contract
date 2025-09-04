// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title EnglishAuction
 * @dev A contract for conducting a classic English-style (price goes up) auction for an ERC-721 NFT.
 * This contract incorporates the withdrawal pattern for enhanced security.
 */
contract EnglishAuction is ReentrancyGuard {

    enum AuctionState { CREATED, STARTED, ENDED, CANCELED }

    struct Auction {
        address payable seller;
        IERC721 nftContract;
        uint256 tokenId;
        uint256 startingBid;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        uint256 duration;
        AuctionState state;
    }

    // A single auction instance is managed by this contract.
    // This can be extended with a mapping to support multiple auctions.
    Auction public auction;

    // Mapping to store funds for bidders who have been outbid.
    mapping(address => uint256) public pendingWithdrawals;

    // Events
    event AuctionCreated(address indexed seller, uint256 startingBid, uint256 duration);
    event AuctionStarted(uint256 endTime);
    event AuctionEnded(address winner, uint256 amount);
    event AuctionCanceled();
