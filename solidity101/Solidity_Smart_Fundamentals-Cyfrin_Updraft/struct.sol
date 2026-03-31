// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; //this is solidity version , ^ for current and newer


contract SimpleStorage {


    struct Person {
        uint favouriteNumber;
        string name;
    }

    Person public orbitalFinance = Person(21,"Santo");
    Person public myFriend = Person({favouriteNumber : 77,name :  "Bob"});
    Person public p;
    Person[] public listOfPeople;

    function changePerson(uint256 _favouriteNumber, string calldata name) public {
        p.favouriteNumber = _favouriteNumber;
        p.name = name;
    }

    function addPerson(uint256 _favouriteNumber, string calldata _name) public {
        listOfPeople.push(Person(_favouriteNumber,_name));
    }

}

