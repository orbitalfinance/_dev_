// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {PriceConverter} from "./priceConverter.sol" ;

error NotOwner(); //more gas efficient than requiire

contract FundMe{

    //using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 5e18;
    address[] public funders;
    mapping(address funder => uint amount) public funderToAmount;
    address public immutable owner;

    constructor(){
        owner = msg.sender;
    }

    // Get funds from Users
    function fund() public payable { 


        //require(msg.value.getConversionRate() > minimumUsd, "Amount below the minimum allowed limit");  //msg.value is managed as an integer in wei
        require(PriceConverter.getConversionRate(msg.value) > MINIMUM_USD, "Amount below the minimum allowed limit"); 
        
        // "revert" undo any action done and send the remaining gas back. A failing function call consumes gas
        // An API call would fail because of consensus problems 
        funders.push(msg.sender);
        funderToAmount[msg.sender] = funderToAmount[msg.sender] + msg.value;
    }
    
    function withdraw() public onlyOwner{


        for(uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address  funder = funders[funderIndex];
            funderToAmount[funder] = 0;
        }

        funders = new address[](0); //new used to reset an array

        //withdraw the funds: transfer and send are deprecated. Call is the one to be used
        (bool callSuccess, /*bytes memory dataReturned*/) = payable(msg.sender).call{value:address(this).balance}(""); // no cap gas
        require(callSuccess,"Withdrawn failed.");

    }

    modifier onlyOwner(){

        if(msg.sender != owner){
            revert NotOwner();
        }
        _;
    }

    //What happend is someone sends this contract ETH without calling fund()?
    //receive
    receive() external payable{
        fund();
    }
    //fallback
    fallback() external payable{
    fund();
    }

}