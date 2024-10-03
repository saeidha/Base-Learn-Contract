// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AddressBook is Ownable {
    struct Contact {
        uint id;
        string firstName;
        string lastName;
        uint[] phoneNumbers;
    }

    Contact[] contacts;

constructor() Ownable(msg.sender) {

}

    function addContact(uint _id, string memory _firstName, string memory _lastName, uint[] memory _phoneNumbers) public onlyOwner {
        contacts.push(Contact(_id, _firstName, _lastName, _phoneNumbers));
    }

    error ContactNotFound(uint _id);
    function deleteContact(uint _id) public onlyOwner {
        for (uint i = 0; i < contacts.length; i++) {
            if (contacts[i].id == _id) {
                delete contacts[i];
                return;
            }
        }
        revert ContactNotFound(_id);
    }

    function getContact(uint _id) public view returns (Contact memory) {
        for (uint i = 0; i < contacts.length; i++) {
            if (contacts[i].id == _id) {
                return contacts[i];
            }
        }
        revert ContactNotFound(_id);
    }

    function getAllContacts() public view returns (Contact[] memory) {
        return contacts;
    }
}

contract AddressBookFactory {
    function deploy() public returns (address) {
        AddressBook newAddressBook = new AddressBook();
        return address(newAddressBook);
    }
}