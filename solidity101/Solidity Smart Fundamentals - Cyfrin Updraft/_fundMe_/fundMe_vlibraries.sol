// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {PriceConverter} from "./priceConverter.sol" ;

contract FundMe{

    //using PriceConverter for uint256;

    uint256 public minimumUsd = 5e18;
    address[] public funders;
    mapping(address funder => uint amount) public funderToAmount;

    // Get funds from Users
    function fund() public payable { 


        //require(msg.value.getConversionRate() > minimumUsd, "Amount below the minimum allowed limit");  //msg.value is managed as an integer in wei
        require(PriceConverter.getConversionRate(msg.value) > minimumUsd, "Amount below the minimum allowed limit"); 
        
        // "revert" undo any action done and send the remaining gas back. A failing function call consumes gas
        // An API call would fail because of consensus problems 
        funders.push(msg.sender);
        funderToAmount[msg.sender] = funderToAmount[msg.sender] + msg.value;
    }
    


}