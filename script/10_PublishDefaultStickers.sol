// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";
import "../src/StickerDesigns.sol";

contract PublishDefaultStickers is Script {
    struct StickerConfig {
        address payoutAddress;
        uint64 price;
        uint256 paymentMethodId;
        uint64 limitCount;
        uint64 limitTime;
        address limitToHolders;
        string metadataCID;
        string imageCID;
    }

    function run() external {
        address payable stickerDesignsContractAddress = payable(vm.envAddress('STICKER_DESIGNS_CONTRACT'));
        require(stickerDesignsContractAddress != address(0), 'DeployStickers: STICKER_DESIGNS_CONTRACT not set');

        // Read and parse JSON config
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/DefaultStickerDesigns.json");
        string memory json = vm.readFile(path);

        // Parse JSON using StdJson
        bytes[] memory metadatas = stdJson.readBytesArray(json, "metadatas");
        string[] memory images = stdJson.readStringArray(json, "images");
        uint256 count = metadatas.length;
        console.log("Found %d stickers to publish", count);

        vm.startBroadcast();

        // Publish each sticker
        for(uint i = 0; i < count; i++) {
            bytes memory metadataCID = metadatas[i];

            // Convert string CIDs to bytes
            string memory imageCID = images[i];

            // Create NewStickerDesign struct
            NewStickerDesign memory sticker = NewStickerDesign({
                payoutAddress: address(this),
                price: 0,
                paymentMethodId: 0,
                limitCount: 0,
                limitTime: 0,
                limitToHolders: address(0),
                metadataCID: metadataCID,
                imageCID: imageCID
            });

            // Calculate required fee
            uint256 requiredFee = StickerDesigns(stickerDesignsContractAddress).costToPublish(address(this));

            // Publish sticker
            console.log("Publishing sticker %d with image CID: %s", i + 1, imageCID);
            StickerDesigns(stickerDesignsContractAddress).publishStickerDesign{value: requiredFee}(sticker);
        }

        vm.stopBroadcast();
    }
}