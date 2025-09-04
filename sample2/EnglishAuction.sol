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
