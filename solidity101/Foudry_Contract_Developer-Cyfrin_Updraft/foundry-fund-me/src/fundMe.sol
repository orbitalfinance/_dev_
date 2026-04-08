// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./generalPriceConverter.sol";

error FundMe__NotOwner(); //more gas efficient than requiire

contract FundMe {
    //using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 5e18;
    address private immutable i_owner;

    address private s_addressFeed;
    address[] private s_funders; // s_ :storage
    mapping(address funder => uint amount) private s_funderToAmount;

    constructor(address _addressFeed) {
        i_owner = msg.sender;
        s_addressFeed = _addressFeed;
    }

    // Get funds from Users
    function fund() public payable {
        //require(msg.value.getConversionRate() > minimumUsd, "Amount below the minimum allowed limit");  //msg.value is managed as an integer in wei
        require(
            PriceConverter.getConversionRate(msg.value, s_addressFeed) >
                MINIMUM_USD,
            "Amount below the minimum allowed limit"
        );

        // "revert" undo any action done and send the remaining gas back. A failing function call consumes gas
        // An API call would fail because of consensus problems
        s_funders.push(msg.sender);
        s_funderToAmount[msg.sender] = s_funderToAmount[msg.sender] + msg.value;
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;

        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_funderToAmount[funder] = 0;
        }

        s_funders = new address[](0); //new used to reset an array

        //withdraw the funds: transfer and send are deprecated. Call is the one to be used
        (bool callSuccess /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}(""); // no cap gas
        require(callSuccess, "Withdrawn failed.");
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_funderToAmount[funder] = 0;
        }

        s_funders = new address[](0); //new used to reset an array

        //withdraw the funds: transfer and send are deprecated. Call is the one to be used
        (bool callSuccess /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}(""); // no cap gas
        require(callSuccess, "Withdrawn failed.");
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    function getVersion() public view returns (uint256) {
        return AggregatorV3Interface(s_addressFeed).version();
    }

    //What happend is someone sends this contract ETH without calling fund()?
    //receive
    receive() external payable {
        fund();
    }

    //fallback
    fallback() external payable {
        fund();
    }

    /**
     * View / Pure functions (Gettersw)
     *
     */

    function getAddresToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_funderToAmount[fundingAddress];
    }

    function getFunder(uint256 funderIndex) external view returns (address) {
        return s_funders[funderIndex];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
