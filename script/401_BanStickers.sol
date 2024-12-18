pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerDesigns.sol";

contract BanStickerDesigns is Script {
    function run(uint256[] calldata stickerIdsToBan) external {
        address payable stickerDesignsContractAddress = payable(vm.envAddress('STICKER_DESIGNS_CONTRACT'));
        require(stickerDesignsContractAddress != address(0), 'BanStickerDesigns: STICKER_DESIGNS_CONTRACT not set');
        StickerDesigns stickerDesigns = StickerDesigns(stickerDesignsContractAddress);

        vm.startBroadcast();
        stickerDesigns.banStickerDesigns(stickerIdsToBan, false); // false to ban, true to unban
        vm.stopBroadcast();
    }
}