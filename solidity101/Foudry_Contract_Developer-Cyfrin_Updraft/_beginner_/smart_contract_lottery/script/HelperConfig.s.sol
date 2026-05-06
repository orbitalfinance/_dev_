//SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    // VRF Mock values
    uint96 public MOCK_BASE_FEE = 0.001 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    int256 public MOCK_WEI_PER_UNIT_LINK = 4e15;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant ETH_CHAIN_ID = 1;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig_InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        } else if (block.chainid == ETH_CHAIN_ID) {
            networkConfigs[ETH_CHAIN_ID] = getMainnetEthConfig();
        } else if (block.chainid == LOCAL_CHAIN_ID) {
            networkConfigs[LOCAL_CHAIN_ID] = getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig_InvalidChainId();
        }
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig_InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 50000,
            subscriptionId: 62857053187117863858646890810176998402979316412215365807599411237967862160879,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x35EE666A5Dd7074E04373f009393535087279da0
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory mainnetConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9,
            callbackGasLimit: 50000,
            subscriptionId: 0,
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            account: 0x35EE666A5Dd7074E04373f009393535087279da0
        });
        return mainnetConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        } else {
            // Deploy mock
            vm.startBroadcast();

            VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
                    MOCK_BASE_FEE,
                    MOCK_GAS_PRICE_LINK,
                    MOCK_WEI_PER_UNIT_LINK
                );

            LinkToken linkToken = new LinkToken();
            vm.stopBroadcast();

            localNetworkConfig = NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30, // seconds
                vrfCoordinator: address(vrfCoordinatorMock),
                gasLane: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9, //doesn't matter
                callbackGasLimit: 50000,
                subscriptionId: 0,
                link: address(linkToken),
                account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
            });
            return localNetworkConfig;
        }
    }
}
