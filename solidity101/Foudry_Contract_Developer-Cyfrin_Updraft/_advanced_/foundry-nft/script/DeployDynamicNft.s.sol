// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "../lib/forge-std/src/Script.sol";
import {DynamicNft} from "../src/DynamicNft.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DeployDynamicNft is Script {
    function run() external returns (DynamicNft) {
        string memory redSvg = vm.readFile("./img/redLogo.svg");
        string memory greenSvg = vm.readFile("./img/greenLogo.svg");

        string memory redLogoUri = svgToImageURI(redSvg);
        string memory greenLogoUri = svgToImageURI(greenSvg);

        vm.startBroadcast();
        DynamicNft dynamicNft = new DynamicNft(redLogoUri, greenLogoUri);
        vm.stopBroadcast();

        return dynamicNft;
    }

    function svgToImageURI(
        string memory svg
    ) public pure returns (string memory) {
        string memory baseURI = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );

        return string(abi.encodePacked(baseURI, svgBase64Encoded));
    }
}
