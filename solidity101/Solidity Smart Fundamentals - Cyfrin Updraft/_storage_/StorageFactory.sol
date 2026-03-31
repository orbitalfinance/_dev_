// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {SimpleStorage} from "./SimpleStorage.sol"; // {a,b,c} , p

 contract StorageFactory{

    SimpleStorage[] public listOfSimpleStorage;

    function createSimpleStorageContract() public {
        // How does the StorageFactory know what the SimpleStorage looks like?
        listOfSimpleStorage.push(new SimpleStorage());  // way to deploy a new contract
        
    }

    function sfAddPerson(string memory _newName, uint256 _newFavouriteNumber, uint _simpleStorageIdx) public {
        /* 
        to interact with a function of an imported contract is needed:
        - an address
        - the ABI (Application Binary Interface) data (function selector)
        */
        SimpleStorage simpleStorageAtIdx = listOfSimpleStorage[_simpleStorageIdx];
        simpleStorageAtIdx.addPerson(_newFavouriteNumber, _newName);
    }

    function sfgGet(uint256 _simpleStorageIdx, string memory _name) public view returns(uint256){
        uint256 favouriteNumber = listOfSimpleStorage[_simpleStorageIdx].findPerson(_name);
        return favouriteNumber;
    } 

 }



