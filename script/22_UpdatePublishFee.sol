pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerDesigns.sol";


contract UpdatePublishFee is Script {
    function run() external {
        address payable stickerDesignsContractAddress = payable(vm.envAddress('STICKER_DESIGNS_CONTRACT'));
        require(stickerDesignsContractAddress != address(0), 'DeployStickers: STICKER_DESIGNS_CONTRACT not set');
        StickerDesigns stickerDesigns = StickerDesigns(stickerDesignsContractAddress);
        vm.startBroadcast();
        stickerDesigns.setPublisherReputationFee(0.0005 ether);
        stickerDesigns.setStickerRegistrationFee(0.0005 ether);
        vm.stopBroadcast();
    }
}
