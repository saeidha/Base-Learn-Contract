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
    event BidPlaced(address indexed bidder, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    error AuctionNotCreated();
    error AuctionAlreadyStarted();
    error AuctionNotStarted();
    error AuctionEndedOrCanceled();
    error AuctionAlreadyEnded();
    error AuctionNotEnded();
    error AuctionInProgress();
    error OnlySeller();
    error BidTooLow();
    error InvalidDuration();
    error NoFundsToWithdraw();

    /**
     * @notice Creates the auction with specified parameters.
     * @dev The seller must have approved the contract to transfer the NFT beforehand.
     * @param _nftContract The address of the ERC721 token contract.
     * @param _tokenId The ID of the token to be auctioned.
     * @param _startingBid The minimum initial price for the item.
     * @param _duration The duration of the auction in seconds.
     */
    function createAuction(
        address _nftContract,
        uint256 _tokenId,
        uint256 _startingBid,
        uint256 _duration
    ) external {
        if (auction.seller != address(0)) {
            revert AuctionAlreadyStarted();
        }
        if (_duration == 0) {
            revert InvalidDuration();
        }

        auction = Auction({
            seller: payable(msg.sender),
            nftContract: IERC721(_nftContract),
            tokenId: _tokenId,
            startingBid: _startingBid,
            highestBid: 0,
            highestBidder: address(0),
            endTime: 0,
            duration: _duration,
            state: AuctionState.CREATED
        });

        emit AuctionCreated(msg.sender, _startingBid, _duration);
    }

    /**
     * @notice Starts the auction, transferring the NFT into the contract's custody.
     */
    function startAuction() external {
        if (msg.sender != auction.seller) {
            revert OnlySeller();
        }
        if (auction.state != AuctionState.CREATED) {
            revert AuctionAlreadyStarted();
        }
        
        // Transfer the NFT from the seller to this contract
        auction.nftContract.transferFrom(msg.sender, address(this), auction.tokenId);
        
        auction.state = AuctionState.STARTED;
        auction.endTime = block.timestamp + auction.duration;
