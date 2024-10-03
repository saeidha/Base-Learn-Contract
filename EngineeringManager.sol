// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Salaried.sol";
import "./Manager.sol";

contract EngineeringManager is Salaried, Manager {
    constructor(uint _annualSalary, uint _idNumber, uint _managerId) Salaried(_annualSalary, _idNumber, _managerId) {}
}
