//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ListOfNumbers {

    uint256 myfavoriteNumber; // Set t 0
    
    struct Person {
        string name;
        uint256 favoriteNumber;
    }

    Person[] public listOfPeople;
    

    function store(uint256 _favoriteNumber) public {

        myfavoriteNumber= _favoriteNumber;

    }

    function retrieve() public view returns (uint256) {
        return myfavoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public{

        listOfPeople.push(Person(_name, _favoriteNumber));

    }
}