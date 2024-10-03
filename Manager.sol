// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Manager {
    uint[] public employeeIds;

    function addReport(uint _id) public {
        employeeIds.push(_id);
    }

    function resetReports() public {
        delete employeeIds;
    }
}
