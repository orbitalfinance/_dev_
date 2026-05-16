// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "../lib/forge-std/src/Script.sol";
import {CallIt} from "../src/CallIt.sol";

contract DeployCallIt is Script {
    function run() external returns (CallIt) {
        vm.startBroadcast();
        CallIt callIt = new CallIt();
        vm.stopBroadcast();
        return callIt;
    }
}
