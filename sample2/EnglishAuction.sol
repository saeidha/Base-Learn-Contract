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

        emit AuctionStarted(auction.endTime);
    }

    /**
     * @notice Places a bid on the item.
     * @dev The sent value must be higher than the current highest bid plus a 5% increment.
     * The previous highest bidder's funds are made available for withdrawal.
     */
    function bid() external payable nonReentrant {
        if (auction.state != AuctionState.STARTED) {
            revert AuctionNotStarted();
        }
        if (block.timestamp >= auction.endTime) {
            revert AuctionAlreadyEnded();
        }

        uint256 currentBid = msg.value;
        uint256 requiredBid;

        if (auction.highestBidder == address(0)) {
            // First bid
            requiredBid = auction.startingBid;
        } else {
            // Subsequent bids require a 5% increment
            requiredBid = auction.highestBid + (auction.highestBid / 20);
        }

        if (currentBid <= requiredBid) {
            revert BidTooLow();
        }

        if (auction.highestBidder != address(0)) {
            // Refund the previous highest bidder
            pendingWithdrawals[auction.highestBidder] += auction.highestBid;
        }

        auction.highestBid = currentBid;
        auction.highestBidder = msg.sender;

        emit BidPlaced(msg.sender, currentBid);
    }

    /**
     * @notice Ends the auction after the duration has passed.
     * @dev Transfers the NFT to the winner and the funds to the seller.
     */
    function endAuction() external nonReentrant {
        if (auction.state != AuctionState.STARTED) {
            revert AuctionNotStarted();
        }
        if (block.timestamp < auction.endTime) {
            revert AuctionInProgress();
        }
        
        auction.state = AuctionState.ENDED;
        
        if (auction.highestBidder != address(0)) {
            // Transfer NFT to the winner
            auction.nftContract.safeTransferFrom(address(this), auction.highestBidder, auction.tokenId);
            // Transfer funds to the seller
            auction.seller.transfer(auction.highestBid);
            
            emit AuctionEnded(auction.highestBidder, auction.highestBid);
        } else {
            // If no bids, return NFT to the seller
            auction.nftContract.safeTransferFrom(address(this), auction.seller, auction.tokenId);
            emit AuctionEnded(address(0), 0);
        }
    }
    
    /**
     * @notice Allows the seller to cancel the auction before it ends if there are no bids.
     */
    function cancelAuction() external {
        if (msg.sender != auction.seller) revert OnlySeller();
        if (auction.state != AuctionState.STARTED) revert AuctionNotStarted();
        if (auction.highestBidder != address(0)) revert("Cannot cancel with active bids");
        if (block.timestamp >= auction.endTime) revert AuctionAlreadyEnded();

        auction.state = AuctionState.CANCELED;
        auction.nftContract.safeTransferFrom(address(this), auction.seller, auction.tokenId);

        emit AuctionCanceled();
    }

    /**
     * @notice Allows outbid users to withdraw their funds.
     */
    function withdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
