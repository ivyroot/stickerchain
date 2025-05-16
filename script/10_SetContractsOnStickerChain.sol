pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerChain.sol";
import "../src/StickerObjectives.sol";
import "../src/PayoutMethod.sol";
import "../src/renderers/SlapMetaRendererV1.sol";

contract SetContractsOnStickerChain is Script {
    function run() external {
        address payable stickerChainContractAddress = payable(vm.envAddress('STICKER_CHAIN_CONTRACT'));
        require(stickerChainContractAddress != address(0), 'SetContractsOnStickerChain: STICKER_CHAIN_CONTRACT not set');
        StickerChain stickerChain = StickerChain(stickerChainContractAddress);

        // Get contract addresses from environment
        address stickerObjectivesAddress = vm.envAddress('STICKER_OBJECTIVES_CONTRACT');
        address publisherPayoutMethodAddress = vm.envAddress('PUBLISHER_PAYOUT_METHOD_CONTRACT');
        address objectivePayoutMethodAddress = vm.envAddress('OBJECTIVE_PAYOUT_METHOD_CONTRACT');
        address slapMetaRendererAddress = vm.envAddress('SLAP_META_RENDERER_CONTRACT');

        require(stickerObjectivesAddress != address(0), 'SetContractsOnStickerChain: STICKER_OBJECTIVES_CONTRACT not set');
        require(publisherPayoutMethodAddress != address(0), 'SetContractsOnStickerChain: PUBLISHER_PAYOUT_METHOD_CONTRACT not set');
        require(objectivePayoutMethodAddress != address(0), 'SetContractsOnStickerChain: OBJECTIVE_PAYOUT_METHOD_CONTRACT not set');
        require(slapMetaRendererAddress != address(0), 'SetContractsOnStickerChain: SLAP_META_RENDERER_CONTRACT not set');

        vm.startBroadcast();
        // Set all contracts on StickerChain
        stickerChain.setStickerObjectivesContract(payable(stickerObjectivesAddress));
        stickerChain.setPublisherPayoutMethodContract(payable(publisherPayoutMethodAddress));
        stickerChain.setObjectivePayoutMethodContract(payable(objectivePayoutMethodAddress));
        stickerChain.setMetadataRendererContract(slapMetaRendererAddress);
        vm.stopBroadcast();
    }
}
