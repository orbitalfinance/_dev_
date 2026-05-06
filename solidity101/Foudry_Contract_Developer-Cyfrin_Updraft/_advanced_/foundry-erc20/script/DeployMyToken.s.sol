// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "../lib/forge-std/src/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract DeployMyToken is Script {
    uint256 public constant INITIAL_SUPPLY = 21 ether;

    function run() external returns (MyToken) {
        vm.startBroadcast();
        MyToken mt = new MyToken(INITIAL_SUPPLY);
        vm.stopBroadcast();
        return mt;
    }
}
