//SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "../lib/forge-std/src/Script.sol";
import "../src/fundMe.sol";
import {HelperConfig} from "./helperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // not a real tx
        HelperConfig newHelperConfig = new HelperConfig(); // Don't broadcast on the network

        // a real tx
        vm.startBroadcast();
        FundMe fundMe = new FundMe(newHelperConfig.activeNetworkConfig());
        vm.stopBroadcast();
        return fundMe;
    }
}
