pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerChain.sol";


contract DeployStickerChain is Script {
    function run() external {
        address initialAdminAddress = vm.envAddress('INITIAL_ADMIN');
        address payable paymentMethodContractAddress = payable(vm.envAddress('PAYMENT_METHOD_CONTRACT'));
        require(paymentMethodContractAddress != address(0), 'DeployStickers: PAYMENT_METHOD_CONTRACT not set');
        address payable stickerDesignsContractAddress = payable(vm.envAddress('STICKER_DESIGNS_CONTRACT'));
        require(stickerDesignsContractAddress != address(0), 'DeployStickers: STICKER_DESIGNS_CONTRACT not set');
        vm.startBroadcast();
        new StickerChain(initialAdminAddress, 0.0005 ether, stickerDesignsContractAddress, paymentMethodContractAddress);
        vm.stopBroadcast();
    }
}