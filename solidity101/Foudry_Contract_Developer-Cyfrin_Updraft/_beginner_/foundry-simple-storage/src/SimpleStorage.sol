// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract SimpleStorage {
    mapping(string name => uint favouriteNumber) public nameToNumber;

    function addPerson(uint256 _favouriteNumber, string calldata _name) public {
        nameToNumber[_name] = _favouriteNumber;
    }

    function findPerson(string calldata _name) public view returns (uint) {
        uint favouriteNumber = nameToNumber[_name];
        return favouriteNumber;
    }
}
