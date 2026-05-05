//SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external {
        deployRaffle();
    }

    function deployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig newHelperConfig = new HelperConfig();

        // local -> deploy mock -> get local config
        // sepolia -> get sepolia config
        HelperConfig.NetworkConfig memory config = newHelperConfig.getConfig();

        // Create subscription
        if (config.subscriptionId == 0) {
            // Create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscription
                .createSubscription(config.vrfCoordinator, config.account);

            // Fund subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.link,
                config.account
            );
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        // Add consumer (broadcast already in Interactions.sol)
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            config.vrfCoordinator,
            config.subscriptionId,
            address(raffle),
            config.account
        );

        return (raffle, newHelperConfig);
    }
}

// forge verify-contract 0xA7Deda6D9a52A43E39C655453C2F7b3a203Da671 src/Raffle.sol:Raffle --etherscan-api-key $ETHERSCAN_API_KEY --rpc-url $SEPOLIA_RPC_URL --show-standard-json-input > json.json
