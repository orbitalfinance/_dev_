// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Encoder} from "../src/Encoder.sol";

contract DeployEncoder is Script {
    function run() external returns (Encoder) {
        vm.startBroadcast();
        Encoder enc = new Encoder();
        vm.stopBroadcast();
        return enc;
    }
}
