// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {DeployMyToken} from "../script/DeployMyToken.s.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken public myToken;
    DeployMyToken public deployer;

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address spender = makeAddr("spender");
    address receiver = makeAddr("receiver");

    uint256 public constant STARTING_BALANCE = 2 ether;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function setUp() public {
        deployer = new DeployMyToken();
        myToken = deployer.run();

        vm.prank(msg.sender);
        myToken.transfer(user1, STARTING_BALANCE);
    }

    function testUser1Balance() public view {
        assertEq(STARTING_BALANCE, myToken.balanceOf(user1));
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 0.5 ether;
        uint256 transferAmount = 0.2 ether;

        vm.prank(user1);
        myToken.approve(user2, initialAllowance);

        vm.prank(user2);
        myToken.transferFrom(user1, user2, transferAmount);

        assertEq(myToken.balanceOf(user2), transferAmount);
        assertEq(myToken.balanceOf(user1), STARTING_BALANCE - transferAmount);
    }

    function testNameIsCorrect() public view {
        assertEq(myToken.name(), "Slingshot");
    }

    function testSymbolIsCorrect() public view {
        assertEq(myToken.symbol(), "SLING");
    }

    function testDecimalsIsEighteen() public view {
        assertEq(myToken.decimals(), 18);
    }

    function testTotalSupplyIsInitialSupply() public view {
        assertEq(myToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testMsgSenderBalanceAfterSetupTransfer() public view {
        assertEq(
            myToken.balanceOf(msg.sender),
            deployer.INITIAL_SUPPLY() - STARTING_BALANCE
        );
    }

    function testUser2StartsWithZeroBalance() public view {
        assertEq(myToken.balanceOf(user2), 0);
    }

    function testTransferWorks() public {
        uint256 amount = 0.5 ether;

        vm.prank(user1);
        bool success = myToken.transfer(user2, amount);

        assertTrue(success);
        assertEq(myToken.balanceOf(user1), STARTING_BALANCE - amount);
        assertEq(myToken.balanceOf(user2), amount);
    }

    function testTransferReturnsTrue() public {
        vm.prank(user1);
        bool success = myToken.transfer(user2, 1 ether);

        assertTrue(success);
    }

    function testTransferEntireBalance() public {
        vm.prank(user1);
        myToken.transfer(user2, STARTING_BALANCE);

        assertEq(myToken.balanceOf(user1), 0);
        assertEq(myToken.balanceOf(user2), STARTING_BALANCE);
    }

    function testTransferZeroAmount() public {
        vm.prank(user1);
        bool success = myToken.transfer(user2, 0);

        assertTrue(success);
        assertEq(myToken.balanceOf(user1), STARTING_BALANCE);
        assertEq(myToken.balanceOf(user2), 0);
    }

    function testTransferEmitsTransferEvent() public {
        uint256 amount = 0.5 ether;

        vm.expectEmit(true, true, false, true, address(myToken));
        emit Transfer(user1, user2, amount);

        vm.prank(user1);
        myToken.transfer(user2, amount);
    }

    function testTransferRevertsIfBalanceIsInsufficient() public {
        vm.prank(user1);
        vm.expectRevert();
        myToken.transfer(user2, STARTING_BALANCE + 1);
    }

    function testTransferRevertsToZeroAddress() public {
        vm.prank(user1);
        vm.expectRevert();
        myToken.transfer(address(0), 1 ether);
    }

    function testTransferDoesNotChangeTotalSupply() public {
        uint256 totalSupplyBefore = myToken.totalSupply();

        vm.prank(user1);
        myToken.transfer(user2, 1 ether);

        assertEq(myToken.totalSupply(), totalSupplyBefore);
    }

    function testApproveWorks() public {
        uint256 allowanceAmount = 1 ether;

        vm.prank(user1);
        bool success = myToken.approve(spender, allowanceAmount);

        assertTrue(success);
        assertEq(myToken.allowance(user1, spender), allowanceAmount);
    }

    function testApproveReturnsTrue() public {
        vm.prank(user1);
        bool success = myToken.approve(spender, 1 ether);

        assertTrue(success);
    }

    function testAllowanceStartsAtZero() public view {
        assertEq(myToken.allowance(user1, spender), 0);
    }

    function testAllowanceBetweenUnrelatedAccountsIsZero() public view {
        assertEq(myToken.allowance(user2, user3), 0);
    }

    function testApproveZeroAmount() public {
        vm.prank(user1);
        bool success = myToken.approve(spender, 0);

        assertTrue(success);
        assertEq(myToken.allowance(user1, spender), 0);
    }

    function testApproveCanOverwriteExistingAllowance() public {
        vm.prank(user1);
        myToken.approve(spender, 1 ether);

        vm.prank(user1);
        myToken.approve(spender, 0.25 ether);

        assertEq(myToken.allowance(user1, spender), 0.25 ether);
    }

    function testApproveCanResetAllowanceToZero() public {
        vm.prank(user1);
        myToken.approve(spender, 1 ether);

        vm.prank(user1);
        myToken.approve(spender, 0);

        assertEq(myToken.allowance(user1, spender), 0);
    }

    function testApproveMaxUintAllowance() public {
        vm.prank(user1);
        myToken.approve(spender, type(uint256).max);

        assertEq(myToken.allowance(user1, spender), type(uint256).max);
    }

    function testApproveEmitsApprovalEvent() public {
        uint256 allowanceAmount = 1 ether;

        vm.expectEmit(true, true, false, true, address(myToken));
        emit Approval(user1, spender, allowanceAmount);

        vm.prank(user1);
        myToken.approve(spender, allowanceAmount);
    }

    function testApproveRevertsForZeroAddressSpender() public {
        vm.prank(user1);
        vm.expectRevert();
        myToken.approve(address(0), 1 ether);
    }

    function testTransferFromWorksAndReducesAllowance() public {
        uint256 initialAllowance = 0.5 ether;
        uint256 transferAmount = 0.2 ether;

        vm.prank(user1);
        myToken.approve(spender, initialAllowance);

        vm.prank(spender);
        bool success = myToken.transferFrom(user1, receiver, transferAmount);

        assertTrue(success);
        assertEq(myToken.balanceOf(receiver), transferAmount);
        assertEq(myToken.balanceOf(user1), STARTING_BALANCE - transferAmount);
        assertEq(
            myToken.allowance(user1, spender),
            initialAllowance - transferAmount
        );
    }

    function testTransferFromReturnsTrue() public {
        vm.prank(user1);
        myToken.approve(spender, 1 ether);

        vm.prank(spender);
        bool success = myToken.transferFrom(user1, receiver, 0.5 ether);

        assertTrue(success);
    }

    function testTransferFromCanSpendEntireAllowance() public {
        uint256 allowanceAmount = 0.5 ether;

        vm.prank(user1);
        myToken.approve(spender, allowanceAmount);

        vm.prank(spender);
        myToken.transferFrom(user1, receiver, allowanceAmount);

        assertEq(myToken.balanceOf(receiver), allowanceAmount);
        assertEq(myToken.allowance(user1, spender), 0);
    }

    function testTransferFromZeroAmount() public {
        uint256 allowanceAmount = 1 ether;

        vm.prank(user1);
        myToken.approve(spender, allowanceAmount);

        vm.prank(spender);
        bool success = myToken.transferFrom(user1, receiver, 0);

        assertTrue(success);
        assertEq(myToken.balanceOf(user1), STARTING_BALANCE);
        assertEq(myToken.balanceOf(receiver), 0);
        assertEq(myToken.allowance(user1, spender), allowanceAmount);
    }

    function testTransferFromRevertsWithoutAllowance() public {
        vm.prank(spender);
        vm.expectRevert();
        myToken.transferFrom(user1, receiver, 1 ether);
    }

    function testTransferFromRevertsIfAllowanceIsTooLow() public {
        vm.prank(user1);
        myToken.approve(spender, 0.1 ether);

        vm.prank(spender);
        vm.expectRevert();
        myToken.transferFrom(user1, receiver, 0.2 ether);
    }

    function testTransferFromRevertsIfBalanceIsTooLow() public {
        uint256 amount = STARTING_BALANCE + 1;

        vm.prank(user1);
        myToken.approve(spender, amount);

        vm.prank(spender);
        vm.expectRevert();
        myToken.transferFrom(user1, receiver, amount);
    }

    function testTransferFromRevertsToZeroAddress() public {
        vm.prank(user1);
        myToken.approve(spender, 1 ether);

        vm.prank(spender);
        vm.expectRevert();
        myToken.transferFrom(user1, address(0), 1 ether);
    }

    function testTransferFromEmitsTransferEvent() public {
        uint256 allowanceAmount = 1 ether;
        uint256 transferAmount = 0.4 ether;

        vm.prank(user1);
        myToken.approve(spender, allowanceAmount);

        vm.expectEmit(true, true, false, true, address(myToken));
        emit Transfer(user1, receiver, transferAmount);

        vm.prank(spender);
        myToken.transferFrom(user1, receiver, transferAmount);
    }

    function testInfiniteAllowanceDoesNotDecrease() public {
        uint256 transferAmount = 0.2 ether;

        vm.prank(user1);
        myToken.approve(spender, type(uint256).max);

        vm.prank(spender);
        myToken.transferFrom(user1, receiver, transferAmount);

        assertEq(myToken.balanceOf(receiver), transferAmount);
        assertEq(myToken.allowance(user1, spender), type(uint256).max);
    }

    function testMultipleTransfers() public {
        uint256 firstAmount = 0.4 ether;
        uint256 secondAmount = 0.3 ether;

        vm.prank(user1);
        myToken.transfer(user2, firstAmount);

        vm.prank(user1);
        myToken.transfer(user3, secondAmount);

        assertEq(
            myToken.balanceOf(user1),
            STARTING_BALANCE - firstAmount - secondAmount
        );
        assertEq(myToken.balanceOf(user2), firstAmount);
        assertEq(myToken.balanceOf(user3), secondAmount);
    }

    function testReceiverCanTransferReceivedTokens() public {
        uint256 amount = 0.5 ether;

        vm.prank(user1);
        myToken.transfer(receiver, amount);

        vm.prank(receiver);
        myToken.transfer(user2, amount);

        assertEq(myToken.balanceOf(receiver), 0);
        assertEq(myToken.balanceOf(user2), amount);
    }

    function testConstructorWithZeroSupply() public {
        MyToken zeroSupplyToken = new MyToken(0);

        assertEq(zeroSupplyToken.totalSupply(), 0);
        assertEq(zeroSupplyToken.balanceOf(address(this)), 0);
        assertEq(zeroSupplyToken.name(), "Slingshot");
        assertEq(zeroSupplyToken.symbol(), "SLING");
    }

    function testConstructorWithCustomSupply() public {
        uint256 customSupply = 100 ether;

        MyToken customToken = new MyToken(customSupply);

        assertEq(customToken.totalSupply(), customSupply);
        assertEq(customToken.balanceOf(address(this)), customSupply);
    }

    function testConstructorEmitsTransferEvent() public {
        uint256 supply = 10 ether;

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), address(this), supply);

        new MyToken(supply);
    }

    function testDeployerInitialSupplyConstant() public view {
        assertEq(deployer.INITIAL_SUPPLY(), 21 ether);
    }

    function testDeployerRunReturnsValidToken() public {
        DeployMyToken newDeployer = new DeployMyToken();
        MyToken newToken = newDeployer.run();

        assertEq(newToken.name(), "Slingshot");
        assertEq(newToken.symbol(), "SLING");
        assertEq(newToken.decimals(), 18);
        assertEq(newToken.totalSupply(), newDeployer.INITIAL_SUPPLY());
    }
}
