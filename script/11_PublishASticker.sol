// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/StickerDesigns.sol";

contract PublishASticker is Script {
    function run(string memory metadataCID, string memory imageCID) external {
        // Get contract address from environment
        address payable stickerDesignsContractAddress = payable(vm.envAddress('STICKER_DESIGNS_CONTRACT'));
        require(stickerDesignsContractAddress != address(0), 'PublishASticker: STICKER_DESIGNS_CONTRACT not set');

        vm.startBroadcast();

        // Create NewStickerDesign struct
        NewStickerDesign memory sticker = NewStickerDesign({
            payoutAddress: address(this),
            price: 0,
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: bytes(metadataCID),
            imageCID: imageCID
        });

        // Calculate required fee
        uint256 requiredFee = StickerDesigns(stickerDesignsContractAddress).costToPublish(address(this));

        // Publish sticker
        console.log("Publishing sticker with image CID: %s", imageCID);
        StickerDesigns(stickerDesignsContractAddress).publishStickerDesign{value: requiredFee}(sticker);

        vm.stopBroadcast();
    }
}
