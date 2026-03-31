// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; //this is solidity version , ^ for current and newer

contract SimpleStorage {
    // Basic types: boolean, uint, int, address, bytes

    uint favouriteNumber; // initialized to 0 if no value is given
    uint public publicFavouriteNumber; // "public" creates the getter of the varible
    /*
    int16 herFavouriteNumber = -15;
    bool hasFavouriteNumber = true;
    string favouriteNumberInText = "twenty-one"; // string as bytes object for text
    address myAddress = 0x35EE666A5Dd7074E04373f009393535087279da0;
    bytes32 favouriteBytes = "cat"; // no bytes64
    */
}
