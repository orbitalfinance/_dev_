//SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() external {}

    function deployRaffle() external returns (Raffle, HelperConfig) {
        HelperConfig newHelperConfig = new HelperConfig();

        // local -> deploy mock -> get local config
        // sepolia -> get sepolia config
        HelperConfig.NetworkConfig memory config = newHelperConfig.getConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        return (raffle, newHelperConfig);
    }
}
