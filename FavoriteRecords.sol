// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FavoriteRecords {
    mapping(string => bool) public approvedRecords;
    mapping(address => mapping(string => bool)) public userFavorites;
    
    string[] private approvedRecordsList;

    error NotApproved(string albumName);

    constructor() {
        string[8] memory initialRecords = [
            "Thriller",
            "Back in Black",
            "The Bodyguard",
            "The Dark Side of the Moon",
            "Their Greatest Hits (1971-1975)",
            "Hotel California",
            "Come On Over",
            "Rumours"
        ];

        for (uint i = 0; i < initialRecords.length; i++) {
            approvedRecords[initialRecords[i]] = true;
            approvedRecordsList.push(initialRecords[i]);
        }
        approvedRecords["Saturday Night Fever"] = true;
        approvedRecordsList.push("Saturday Night Fever");
    }

    function getApprovedRecords() public view returns (string[] memory) {
        return approvedRecordsList;
    }

    function addRecord(string memory albumName) public {
        if (!approvedRecords[albumName]) {
            revert NotApproved(albumName);
        }
        userFavorites[msg.sender][albumName] = true;
    }

    function getUserFavorites(address user) public view returns (string[] memory) {
        uint count = 0;
        for (uint i = 0; i < approvedRecordsList.length; i++) {
            if (userFavorites[user][approvedRecordsList[i]]) {
                count++;
            }
        }

        string[] memory favorites = new string[](count);
        uint index = 0;
        for (uint i = 0; i < approvedRecordsList.length; i++) {
            if (userFavorites[user][approvedRecordsList[i]]) {
                favorites[index] = approvedRecordsList[i];
                index++;
            }
        }

        return favorites;
    }

    function resetUserFavorites() public {
        for (uint i = 0; i < approvedRecordsList.length; i++) {
            if (userFavorites[msg.sender][approvedRecordsList[i]]) {
                userFavorites[msg.sender][approvedRecordsList[i]] = false;
            }
        }
    }
}