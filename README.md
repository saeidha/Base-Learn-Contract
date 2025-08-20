# Base Learn Smart Contract Documentation

## Overview

`AIBasedLockedToken` is a Solidity smart contract that implements a non-transferable ERC20 token. This token is designed for a specific distribution mechanism where whitelisted users can claim a fixed amount of tokens. The contract leverages OpenZeppelin's secure and battle-tested `ERC20` and `Ownable` implementations.

The primary feature of this token is its **non-transferability**; once claimed, tokens cannot be transferred between regular user accounts. This is enforced by overriding the internal `_update` function. The distribution is managed by an owner who can add addresses to a whitelist, allowing them to claim tokens once. There is a maximum limit to the total number of claims that can be made.

-----

## Key Features 📝

  * **ERC20 Standard:** Implements the standard `ERC20` interface for token functionality.
  * **Non-Transferable:** Tokens cannot be transferred between external accounts, only minted (claimed) or burned.
  * **Whitelist System:** Only addresses added to a whitelist by the contract owner can claim tokens.
  * **Ownable:** The contract has an owner with administrative privileges, such as adding addresses to the whitelist. This is managed by OpenZeppelin's `Ownable` contract.
  * **Capped Claims:** There is a hard cap on the total number of claims (`MAX_CLAIMS`) that can ever be processed.
  * **Fixed Claim Amount:** Each whitelisted user can claim a predefined, fixed amount of tokens (`CLAIM_AMOUNT`).

-----

## Contract Details

### State Variables

  * `mapping(address => bool) public whitelist;`
      * A mapping to store addresses that are approved to claim tokens. The owner can add addresses here.
  * `mapping(address => bool) public hasClaimed;`
      * A mapping to track which addresses have already claimed their tokens to prevent double-claiming.
  * `uint256 public totalClaims;`
      * A counter for the total number of claims made so far.
  * `uint256 public constant MAX_CLAIMS = 100;`
      * A constant defining the maximum number of users who can claim tokens.
  * `uint256 public constant CLAIM_AMOUNT = 10 * 10**18;`
      * A constant defining the amount of tokens (10 tokens with 18 decimals) a user receives when they claim.

### Constructor

```solidity
constructor(address initialOwner) ERC20("AIBLockedToken", "AIBL") Ownable(initialOwner) {}
```
