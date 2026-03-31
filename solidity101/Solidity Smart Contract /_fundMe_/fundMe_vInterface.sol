// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


// solhint-disable-next-line interface-starts-with-i
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}


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
        // ABI
    

    }

    function getConversionRate() public {

    }

    function getVersion() public view returns(uint256){
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }
}