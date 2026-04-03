// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "lib/forge-std/src/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract DeploySimpleStorage is Script {
    function run() external returns (SimpleStorage) {
        vm.startBroadcast(); // After this line send everything to the RPC
        //Insert transactions
        SimpleStorage simpleStorage = new SimpleStorage(); // send a transaction to create a new contract
        vm.stopBroadcast();

        return simpleStorage;
    }
}
