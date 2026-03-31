// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; //this is solidity version , ^ for current and newer

contract SimpleStorage {
    uint[] public listOfFavouriteNumbers;

    function store(uint256 _favouriteNumber) public {
        listOfFavouriteNumbers.push(_favouriteNumber);
    }
}
