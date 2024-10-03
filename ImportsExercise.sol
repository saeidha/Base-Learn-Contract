// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SillyStringUtils.sol";

contract ImportsExercise {
    using SillyStringUtils for string;
    
    // Public instance of Haiku
    SillyStringUtils.Haiku public haiku;

    // Function to save Haiku
    function saveHaiku(string memory _line1, string memory _line2, string memory _line3) public {
        haiku = SillyStringUtils.Haiku({
            line1: _line1,
            line2: _line2,
            line3: _line3
        });
    }

    // Function to get Haiku
    function getHaiku() public view returns (SillyStringUtils.Haiku memory) {
        return haiku;
    }

    // Function to return Haiku with shruggie added to line3
    function shruggieHaiku() public view returns (SillyStringUtils.Haiku memory) {
        SillyStringUtils.Haiku memory modifiedHaiku = haiku;
        modifiedHaiku.line3 = haiku.line3.shruggie();
        return modifiedHaiku;
    }
}
