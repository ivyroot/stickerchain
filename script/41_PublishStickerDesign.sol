pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerChain.sol";
import "../src/StickerDesigns.sol";


contract PublishStickerDesign is Script {
    function run() external {
        address payable stickerDesignsContractAddress = payable(vm.envAddress('STICKER_DESIGNS_CONTRACT'));
        require(stickerDesignsContractAddress != address(0), 'DeployStickers: STICKER_DESIGNS_CONTRACT not set');
        StickerDesigns stickerDesigns = StickerDesigns(stickerDesignsContractAddress);

        bytes memory metadataCID1 = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';
        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(tx.origin),
            price: uint64(0),
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadataCID1
        });


        uint256 feeAmount = stickerDesigns.costToPublish(address(this));

        vm.startBroadcast();
        uint256 newStickerId = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);
        vm.stopBroadcast();

        console.log('New Sticker ID:', newStickerId);
    }
}