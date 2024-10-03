// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ControlStructures {
    error AfterHours(uint time);

    function fizzBuzz(uint _number) public pure returns (string memory) {
        if (_number % 3 == 0 && _number % 5 == 0) {
            return "FizzBuzz";
        } else if (_number % 3 == 0) {
            return "Fizz";
        } else if (_number % 5 == 0) {
            return "Buzz";
        } else {
            return "Splat";
        }
    }

    function doNotDisturb(uint _time) public pure returns (string memory) {
        if (_time >= 2400) {
            assert(false); // This will trigger a panic
        }
        
        if (_time > 2200 || _time < 800) {
            revert AfterHours(_time);
        }
        
        if (_time >= 1200 && _time <= 1259) {
            revert("At lunch!");
        }
        
        if (_time >= 800 && _time <= 1199) {
            return "Morning!";
        }
        
        if (_time >= 1300 && _time <= 1799) {
            return "Afternoon!";
        }
        
        if (_time >= 1800 && _time <= 2200) {
            return "Evening!";
        }
        
        // This line should never be reached, but is included to satisfy the compiler
        revert("Invalid time");
    }
}