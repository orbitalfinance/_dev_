
// Set a minimum funding value in Eur


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract FundMe{

    // Get funds from Users
    function fund() public payable { 

        require(msg.value > 1000 gwei, "Amount below the minimum allowed limit"); // "revert" undo any action done and send the remaining gas back. A failing function call consumes gas
    }
    
    // Withdraw funds
    function withdraw() public{

    }

}