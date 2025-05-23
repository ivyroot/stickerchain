pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerChain.sol";
import "../src/PayoutMethod.sol";


contract DeployPublisherPayoutMethod is Script {
    function run() external {
        address initialAdminAddress = vm.envAddress('INITIAL_ADMIN');
        address payable stickerChainContractAddress = payable(vm.envAddress('STICKER_CHAIN_CONTRACT'));
        require(stickerChainContractAddress != address(0), 'DeployPublisherPayoutMethod: STICKER_CHAIN_CONTRACT not set');
        StickerChain stickerChain = StickerChain(stickerChainContractAddress);
        vm.startBroadcast();
        PayoutMethod publisherPayoutMethod = new PayoutMethod(address(stickerChain), initialAdminAddress);
        // stickerChain.setPublisherPayoutMethodContract(payable(address(publisherPayoutMethod)));
        vm.stopBroadcast();
    }
}