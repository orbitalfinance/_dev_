// SPDX-Licence-Identifier: MIT;

pragma solidity ^0.8.30;

import {Test, console} from "../../lib/forge-std/src/Test.sol"; // console is used for debugging using logs
import "../../src/fundMe.sol";
import {DeployFundMe} from "../../script/deployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/interactionsFundMe.s.sol";

contract FundMeIntegrationTest is Test {
    FundMe newFundMe;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        newFundMe = deploy.run();
    }

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(newFundMe));

        address funder = newFundMe.getFunder(0);
        assertEq(funder, msg.sender);
    }

    function testUserCanWithdrawInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(newFundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(newFundMe));

        assert(address(newFundMe).balance == 0);
    }
}
