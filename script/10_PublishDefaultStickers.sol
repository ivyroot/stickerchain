// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
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
        // Get deployer from environment
        address deployer = vm.envAddress("DEPLOYER");
        address stickerDesigns = vm.envAddress("STICKER_DESIGNS");

        // Read and parse JSON config
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/DefaultStickerDesigns.json");
        string memory json = vm.readFile(path);

        // Parse JSON into array of StickerConfig
        bytes memory jsonBytes = vm.parseJson(json);
        StickerConfig[] memory configs = abi.decode(jsonBytes, (StickerConfig[]));

        console.log("Found %d stickers to publish", configs.length);

        vm.startBroadcast(deployer);

        // Publish each sticker
        for(uint i = 0; i < configs.length; i++) {
            StickerConfig memory config = configs[i];

            // Convert string CIDs to bytes
            bytes memory metadataCID = bytes(config.metadataCID);

            // Create NewStickerDesign struct
            NewStickerDesign memory sticker = NewStickerDesign({
                payoutAddress: config.payoutAddress,
                price: config.price,
                paymentMethodId: config.paymentMethodId,
                limitCount: config.limitCount,
                limitTime: config.limitTime,
                limitToHolders: config.limitToHolders,
                metadataCID: metadataCID,
                imageCID: config.imageCID
            });

            // Calculate required fee
            uint256 requiredFee = StickerDesigns(stickerDesigns).costToPublish(deployer);

            // Publish sticker
            console.log("Publishing sticker %d with metadata CID: %s", i + 1, config.metadataCID);
            StickerDesigns(stickerDesigns).publishStickerDesign{value: requiredFee}(sticker);
        }

        vm.stopBroadcast();
    }
}