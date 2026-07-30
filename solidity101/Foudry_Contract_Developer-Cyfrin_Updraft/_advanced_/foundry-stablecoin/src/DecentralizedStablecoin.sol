// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volatility coin

// Layout of Contract:
// Version
// Imports
// Interfaces, libraries, contracts
// Errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// Constructor
// Receive function (if exists)
// Fallback function (if exists)
// External, Public, Internal,Private
// View & pure functions

pragma solidity ^0.8.30;

/*
 * @title DecentralizedStablecoin
 * @author Santo Mancuso from Cyfrin Updraft Course
 *
 * Collateral: Exogenous (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stability: Pegged to USD
 *
 * This is the contract meant to be governed by DSCEngine.
 * This contract is just the ERC20 implementation of our stablecoin system.
 */

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol"; //It's possible to import ERC20 because is imported in the ERC20Burnable
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedStablecoin is ERC20Burnable, Ownable {
    error DecentralizedStablecoin__MustBeMoreThanZero();
    error DecentralizedStablecoin__BurnAmountExceedsBalance();
    error DecentralizedStablecoin__NotZeroAddress();

    constructor() ERC20("DecentralizedStablecoin", "DSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);

        if (_amount <= 0) {
            revert DecentralizedStablecoin__MustBeMoreThanZero();
        }

        if (balance < _amount) {
            revert DecentralizedStablecoin__BurnAmountExceedsBalance();
        }

        super.burn(_amount); //This is needed because the function is being overrided
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStablecoin__NotZeroAddress();
        }

        if (_amount <= 0) {
            revert DecentralizedStablecoin__MustBeMoreThanZero();
        }

        _mint(_to, _amount); // It is not overrided
        return true;
    }
}
