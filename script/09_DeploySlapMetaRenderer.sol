pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerChain.sol";
import "../src/StickerDesigns.sol";
import "../src/renderers/SlapMetaRendererV1.sol";

contract DeploySlapMetaRenderer is Script {
    function run() external {
        address payable stickerChainContractAddress = payable(vm.envAddress('STICKER_CHAIN_CONTRACT'));
        require(stickerChainContractAddress != address(0), 'DeployObjectivePayoutMethod: STICKER_CHAIN_CONTRACT not set');
        StickerChain stickerChain = StickerChain(stickerChainContractAddress);
        address payable stickerDesignsContractAddress = payable(vm.envAddress('STICKER_DESIGNS_CONTRACT'));
        require(stickerDesignsContractAddress != address(0), 'DeployObjectivePayoutMethod: STICKER_DESIGNS_CONTRACT not set');
        StickerDesigns stickerDesigns = StickerDesigns(stickerDesignsContractAddress);
        vm.startBroadcast();
        SlapMetaRendererV1 renderer = new SlapMetaRendererV1(stickerChain, stickerDesigns);
        // stickerChain.setMetadataRendererContract(address(renderer));
        vm.stopBroadcast();
    }
}