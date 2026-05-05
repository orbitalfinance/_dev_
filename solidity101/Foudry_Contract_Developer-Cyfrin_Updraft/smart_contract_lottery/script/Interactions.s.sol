// SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.34;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig newHelperConfig = new HelperConfig();

        address configVRFCoordinator = newHelperConfig
            .getConfig()
            .vrfCoordinator;
        (uint256 subId, ) = createSubscription(
            configVRFCoordinator,
            newHelperConfig.getConfig().account
        );
        // create subscription
        return (subId, configVRFCoordinator);
    }

    function createSubscription(
        address configVRFCoordinator,
        address account
    ) public returns (uint256, address) {
        console.log("Creating subscription on chain Id:", block.chainid);

        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(configVRFCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription Id is:", subId);
        return (subId, configVRFCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig newHelperConfig = new HelperConfig();

        address configVRFCoordinator = newHelperConfig
            .getConfig()
            .vrfCoordinator;

        uint256 subscriptionId = newHelperConfig.getConfig().subscriptionId;
        address linkToken = newHelperConfig.getConfig().link;

        fundSubscription(
            configVRFCoordinator,
            subscriptionId,
            linkToken,
            newHelperConfig.getConfig().account
        );
    }

    function fundSubscription(
        address configVRFCoordinator,
        uint256 subscriptionId,
        address linkToken,
        address account
    ) public {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", configVRFCoordinator);
        console.log("On-ChainId: ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(configVRFCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(
                configVRFCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig newHelperConfig = new HelperConfig();

        uint256 subscriptionId = newHelperConfig.getConfig().subscriptionId;
        address configVRFCoordinator = newHelperConfig
            .getConfig()
            .vrfCoordinator;

        // Add Consumer
        addConsumer(
            configVRFCoordinator,
            subscriptionId,
            mostRecentlyDeployed,
            newHelperConfig.getConfig().account
        );
    }

    function addConsumer(
        address configVRFCoordinator,
        uint256 subscriptionId,
        address consumerAddressToAdd,
        address account
    ) public {
        console.log("Consumer to be added: ", consumerAddressToAdd);
        console.log("To vrfCoordinator: ", configVRFCoordinator);
        console.log("For the subscription Id:", subscriptionId);
        console.log("On chainId:", block.chainid);

        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(configVRFCoordinator).addConsumer(
            subscriptionId,
            consumerAddressToAdd
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
