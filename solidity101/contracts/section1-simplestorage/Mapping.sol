//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//set "HARDHAT_NETWORK=localhost" && node scripts\interact.js Mapping 0xe7f17.... nameToFavoriteNumeber "Santo"

contract Mapping {

    mapping(string => uint256) public nameToFavoriteNumeber;

    function addPerson(string memory _name, uint256 _favoriteNumber) public{

        nameToFavoriteNumeber[_name]=_favoriteNumber;

    }
}