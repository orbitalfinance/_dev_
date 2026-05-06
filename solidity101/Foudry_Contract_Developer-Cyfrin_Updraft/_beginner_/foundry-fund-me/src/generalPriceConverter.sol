// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(address _addressFeed) internal view returns (uint256) {
        // What is needed? Address and ABI
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            _addressFeed // Working with Sepolia 0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        (, int256 price, , , ) = priceFeed.latestRoundData(); // price of ETH in terms of USD
        uint8 decimals = priceFeed.decimals();

        return uint256(price) * 10 ** (18 - decimals);
    }

    function getConversionRate(
        uint256 ethAmount,
        address _addressFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_addressFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}
