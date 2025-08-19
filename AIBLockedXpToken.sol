// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract AIBLockedXpToken is ERC20, Ownable {

    uint256 public maxSupply;
    uint256 public totalClaims;
    uint256 public constant MAX_CLAIMS = 100;
    uint256 public constant CLAIM_AMOUNT = 10 * 10**18;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public hasClaimed;

    constructor(address initialOwner) ERC20("AIBLockedXpToken", "AIBLXP") Ownable(initialOwner) {
        maxSupply = MAX_CLAIMS * CLAIM_AMOUNT;
    }


    function _update(address from, address to, uint256 value) internal override {
        require(from == address(0) || to == address(0), "Token is non-transferable");
        super._update(from, to, value);
    }

    function claim() external {
        require(whitelist[msg.sender], "Not whitelisted");
        require(!hasClaimed[msg.sender], "Already claimed");
        require(totalSupply() + CLAIM_AMOUNT <= maxSupply, "Max supply reached");

        totalClaims++;
        hasClaimed[msg.sender] = true;
        _mint(msg.sender, CLAIM_AMOUNT);
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function updateMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply >= totalSupply(), "New max supply is less than total supply");
        maxSupply = newMaxSupply;
    }
}
