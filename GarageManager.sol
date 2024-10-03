// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GarageManager {
    // Define the Car struct
    struct Car {
        string make;
        string model;
        string color;
        uint numberOfDoors;
    }

    // Public mapping to store a list of Cars, indexed by address
    mapping(address => Car[]) public garage;

    // Custom error for invalid car index
    error BadCarIndex(uint index);

    // Function to add a car to the user's collection in the garage
    function addCar(string memory make, string memory model, string memory color, uint numberOfDoors) public {
        Car memory newCar = Car({
            make: make,
            model: model,
            color: color,
            numberOfDoors: numberOfDoors
        });
        garage[msg.sender].push(newCar);
    }

    // Function to get all cars owned by the calling user
    function getMyCars() public view returns (Car[] memory) {
        return garage[msg.sender];
    }

    // Function to get all cars for any given user address
    function getUserCars(address user) public view returns (Car[] memory) {
        return garage[user];
    }

    // Function to update a car at a specific index for the calling user
    function updateCar(uint index, string memory make, string memory model, string memory color, uint numberOfDoors) public {
        if (index >= garage[msg.sender].length) {
            revert BadCarIndex(index);
        }
        garage[msg.sender][index] = Car({
            make: make,
            model: model,
            color: color,
            numberOfDoors: numberOfDoors
        });
    }

    // Function to reset the calling user's garage
    function resetMyGarage() public {
        delete garage[msg.sender];
    }
}
