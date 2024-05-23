pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerDesigns.sol";


contract DeployStickers is Script {
    function run() external {
        address blockPlacesContractAddress = vm.envAddress('BLOCK_PLACES_CONTRACT');
        require(blockPlacesContractAddress != address(0), 'DeployStickers: BLOCK_PLACES_CONTRACT not set');
        address stickerDesignsContractAddress = vm.envAddress('STICKER_DESIGNS_CONTRACT');
        require(stickerDesignsContractAddress != address(0), 'DeployStickers: STICKER_DESIGNS_CONTRACT not set');
        vm.startBroadcast();
        new StickerDesigns(address(tx.origin), 2000000000000000, 50000000000000);
        vm.stopBroadcast();
    }
}