// SPDX-Licence-Identifier: MIT;

pragma solidity ^0.8.30;

import {Test, console} from "../../lib/forge-std/src/Test.sol"; // console is used for debugging using logs
import "../../src/fundMe.sol";
import {DeployFundMe} from "../../script/deployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe newFundMe;

    // cheatcodes
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe newDeployFundMe = new DeployFundMe();
        newFundMe = newDeployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumUsd() public view {
        assertEq(newFundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsSender() public view {
        assertEq(msg.sender, newFundMe.getOwner());
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = newFundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // Next line should revert! If it does the test pass.abi
        newFundMe.fund(); // 0 is send
    }

    modifier funded() {
        vm.prank(USER); // next transaction will be sent by USER (msg.sender)
        newFundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        //vm.prank(USER); // next transaction will be sent by USER (msg.sender)
        //newFundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = newFundMe.getAddresToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        //vm.prank(USER);
        //newFundMe.fund{value: SEND_VALUE}();

        address funder = newFundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        //vm.prank(USER);
        //newFundMe.fund{value: SEND_VALUE}();

        vm.prank(USER);
        vm.expectRevert();
        newFundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = newFundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(newFundMe).balance; //SEND_VALUE

        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(newFundMe.getOwner());
        newFundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = newFundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(newFundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdraWithMultipleFunders() public funded {
        uint256 numbersOfFunders = 10;
        uint160 startingFunderIndex = 1; // can be converted in address

        for (uint160 i = startingFunderIndex; i < numbersOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            hoax(address(i), SEND_VALUE);
            newFundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = newFundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(newFundMe).balance;

        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(newFundMe.getOwner());
        newFundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = newFundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(newFundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdraWithMultipleFundersCheaper() public funded {
        uint256 numbersOfFunders = 10;
        uint160 startingFunderIndex = 1; // can be converted in address

        for (uint160 i = startingFunderIndex; i < numbersOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            hoax(address(i), SEND_VALUE);
            newFundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = newFundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(newFundMe).balance;

        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(newFundMe.getOwner());
        newFundMe.cheaperWithdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = newFundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(newFundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }
}

// What can we do to work with addresses outside our system?
// 1. Unit
//   - Testing a specific part of our code
// 2. Integration
//   - Testing how our code works with other parts of our code
// 3. Forked
//   - Testing our code on a simulated real environment
// 4. Staging
//   - Testing our code in a real environment that is not prod
