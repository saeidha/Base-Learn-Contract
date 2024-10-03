// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract UnburnableToken {
    mapping(address => uint) public balances;
    mapping(address => bool) public claimed;
    uint public totalSupply;
    uint public totalClaimed;

    constructor() {
        totalSupply = 100000000;
    }

    error TokensClaimed();
    error AllTokensClaimed();
    function claim() public {
        if (claimed[msg.sender]) {
            revert TokensClaimed();
        }

        if (totalClaimed + 1000 >= totalSupply) {
            revert AllTokensClaimed();
        }

        balances[msg.sender] += 1000;
        claimed[msg.sender] = true;
        totalClaimed += 1000;
    }

    error UnsafeTransfer(address _to);
    function safeTransfer(address _to, uint _amount) public {
         if (_to == address(0) || _to.balance == 0) {
            revert UnsafeTransfer(_to);
        }

        if (balances[msg.sender] >= _amount) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
        }
    }
}