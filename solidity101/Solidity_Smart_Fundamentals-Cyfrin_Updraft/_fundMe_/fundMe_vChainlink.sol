// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


contract FundMe{

    uint8 public minimumEur = 5;

    // Get funds from Users
    function fund() public payable { 

        require(msg.value > minimumEur, "Amount below the minimum allowed limit"); 
        // "revert" undo any action done and send the remaining gas back. A failing function call consumes gas
        // An API call would fail because of consensus problems 
    }
    
    // Withdraw funds
    function withdraw() public{

    }


    function getPrice() public {

        // Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // ABI: 

    }

    function getConversionRate() public {

    }
}