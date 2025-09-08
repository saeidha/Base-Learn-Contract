// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title TimeLockWallet
 * @dev A contract that allows an owner to deposit funds and allocate them to beneficiaries.
