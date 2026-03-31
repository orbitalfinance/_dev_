// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {SimpleStorage} from "./mapping.sol";

contract SimpleStoragePlusOne is SimpleStorage {

    function addPerson(uint256 _favouriteNumber, string calldata _name) public override{
        nameToNumber[_name] = _favouriteNumber+1;
    }

}


