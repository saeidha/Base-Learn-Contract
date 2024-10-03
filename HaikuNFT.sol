// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract HaikuNFT is ERC721 {
    struct Haiku {
        address author;
        string line1;
        string line2;
        string line3;
    }

    Haiku[] public haikus;

    mapping(address => uint[]) public sharedHaikus;
    mapping(string => bool) public lineUsed;

    uint public counter;

    error HaikuNotUnique();
    error NotYourHaiku(uint _id);
    error NoHaikusShared();

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        counter = 1;
    }

    function mintHaiku(string memory _line1, string memory _line2, string memory _line3) external {
        if (lineUsed[_line1] || lineUsed[_line2] || lineUsed[_line3]) revert HaikuNotUnique();

        address sender = _msgSender();

        lineUsed[_line1] = true;
        lineUsed[_line2] = true;
        lineUsed[_line3] = true;

        Haiku memory newHaiku = Haiku({
            author: sender,
            line1: _line1,
            line2: _line2,
            line3: _line3
        });

        haikus.push(newHaiku);

        _safeMint(sender, counter);
        counter++;
    }

    function shareHaiku(address _to, uint _id) public {
        require(haikus.length > _id, "Invalid id");

        address sender = _msgSender();

        if (sender != haikus[_id].author) revert NotYourHaiku(_id);

        sharedHaikus[_to].push(_id);
    }

    function getMySharedHaikus() public view returns(uint[] memory) {
        address sender = _msgSender();

        uint[] memory mySharedHaikus = sharedHaikus[sender];

        if (mySharedHaikus.length == 0) revert NoHaikusShared();

        return mySharedHaikus;
    }
}