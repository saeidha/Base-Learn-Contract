# AIBasedLockedToken Smart Contract Documentation

## Overview

`AIBasedLockedToken` is a Solidity smart contract that implements a non-transferable ERC20 token. This token is designed for a specific distribution mechanism where whitelisted users can claim a fixed amount of tokens. The contract leverages OpenZeppelin's secure and battle-tested `ERC20` and `Ownable` implementations.

The primary feature of this token is its **non-transferability**; once claimed, tokens cannot be transferred between regular user accounts. This is enforced by overriding the internal `_update` function. The distribution is managed by an owner who can add addresses to a whitelist, allowing them to claim tokens once. There is a maximum limit to the total number of claims that can be made.
