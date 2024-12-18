// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

import {IERC721A} from  "erc721a/contracts/IERC721A.sol";


import {IMetadataRenderer} from "./IMetadataRenderer.sol";
import {StickerChain, Slap} from "../StickerChain.sol";
import {StickerDesigns} from "../StickerDesigns.sol";


contract SlapMetaRendererV1 is IMetadataRenderer {
    StickerChain public immutable stickerChain;
    StickerDesigns public immutable stickerDesigns;

    constructor(StickerChain _stickerChain, StickerDesigns _stickerDesigns) {
        stickerChain = _stickerChain;
        stickerDesigns = _stickerDesigns;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        Slap memory slap = stickerChain.getSlap(tokenId);
        if (slap.slapId == 0) {
            revert IERC721A.URIQueryForNonexistentToken();
        }

        string memory imageCID = stickerDesigns.getStickerDesignImageCID(slap.stickerId);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                    '{"name": "Slap #: ',
                    Strings.toString(tokenId),
                    '", "stickerId": ',
                    Strings.toString(slap.stickerId),
                    ', "placeId": ',
                    Strings.toString(slap.placeId),
                    ', "height": ',
                    Strings.toString(slap.height),
                    ', "slappedAt": ',
                    Strings.toString(slap.slappedAt),
                    ', "size": "',
                    Strings.toString(slap.size),
                    '", "player": "',
                    Strings.toHexString(slap.player),
                    '", "image": "ipfs://',
                    imageCID,
                    '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }


}

