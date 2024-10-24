pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerChain.sol";
import "../src/StickerObjectives.sol";


contract DeployStickerObjectives is Script {
    function run() external {
        address initialAdminAddress = vm.envAddress('INITIAL_ADMIN');
        address payable stickerChainContractAddress = payable(vm.envAddress('STICKER_CHAIN_CONTRACT'));
        require(stickerChainContractAddress != address(0), 'DeployStickerObjectives: STICKER_CHAIN_CONTRACT not set');
        StickerChain stickerChain = StickerChain(stickerChainContractAddress);
        vm.startBroadcast();
        StickerObjectives stickerObjectives = new StickerObjectives(stickerChainContractAddress, initialAdminAddress, 0.002 ether);
        stickerChain.setStickerObjectivesContract(payable(address(stickerObjectives)));
        vm.stopBroadcast();
    }
}