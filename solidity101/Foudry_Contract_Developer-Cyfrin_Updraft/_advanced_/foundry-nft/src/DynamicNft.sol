// SPDX-License-Identifier:MIT
pragma solidity ^0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DynamicNft is ERC721 {
    uint256 private s_tokenCounter;
    string private s_redLogoSvgUri;
    string private s_greenLogoSvgUri;

    error DynamicNft__CantChangeColorIfNotOwner();

    enum Color {
        GREEN,
        RED
    }
    mapping(uint256 => Color) private s_tokenIdToColor;

    constructor(
        string memory redLogoSvgUri,
        string memory greenLogoSvgUri
    ) ERC721("Logo NFT", "LG") {
        s_tokenCounter = 0;
        s_redLogoSvgUri = redLogoSvgUri;
        s_greenLogoSvgUri = greenLogoSvgUri;
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToColor[s_tokenCounter] = Color.GREEN;
        s_tokenCounter++;
    }

    function changeColor(uint256 tokenId) public {
        // only want the NFT owner or an approved address to be able to change the color
        address owner = ownerOf(tokenId);

        if (
            msg.sender != owner &&
            getApproved(tokenId) != msg.sender &&
            !isApprovedForAll(owner, msg.sender)
        ) {
            revert DynamicNft__CantChangeColorIfNotOwner();
        }

        if (s_tokenIdToColor[tokenId] == Color.RED) {
            s_tokenIdToColor[tokenId] = Color.GREEN;
        } else {
            s_tokenIdToColor[tokenId] = Color.RED;
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory imageURI;

        if (s_tokenIdToColor[tokenId] == Color.RED) {
            imageURI = s_redLogoSvgUri;
        } else {
            imageURI = s_greenLogoSvgUri;
        }

        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(),
                                '", "description": "An NFT that reflects the owners Logo.", "attributes": [{"trait_type": "brightness", "value": 100}], "image": "',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
