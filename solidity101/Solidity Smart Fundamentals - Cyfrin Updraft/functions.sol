// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; //this is solidity version , ^ for current and newer

// Remix VM has a local test blockchain to deploy contracts 
// 2300 gas is the amount to send ethers between accounts (less than modifying the state of the blockchain)

contract SimpleStorage {

    // Basic types: boolean, uint, int, address, bytes
    
    uint favouriteNumber; // initialized to 0 if no value is given
    uint public publicFavouriteNumber;   // "public" creates the getter of the varible
    /*
    int16 herFavouriteNumber = -15;
    bool hasFavouriteNumber = true;
    string favouriteNumberInText = "twenty-one"; // string as bytes object for text
    address myAddress = 0x35EE666A5Dd7074E04373f009393535087279da0;
    bytes32 favouriteBytes = "cat"; // no bytes64
    */
    
    function retrieve() public view returns(uint){
        return favouriteNumber;
    }

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }


    // external is a visibility specifier only for functions !!
    // view functions in general don't spend gas except when are called by a function tha does it
    function increase() public returns(uint){
        favouriteNumber += 1;
        return retrieve();
    }
}

