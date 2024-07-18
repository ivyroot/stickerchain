pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerChain.sol";
import "../src/PayoutMethod.sol";


contract DeployPublisherPayoutMethod is Script {
    function run() external {
        address payable stickerChainContractAddress = payable(vm.envAddress('STICKER_CHAIN_CONTRACT'));
        require(stickerChainContractAddress != address(0), 'DeployPublisherPayoutMethod: STICKER_CHAIN_CONTRACT not set');
        StickerChain stickerChain = StickerChain(stickerChainContractAddress);
        vm.startBroadcast();
        PayoutMethod publisherPayoutMethod = new PayoutMethod(address(stickerChain), address(tx.origin));
        stickerChain.setPublisherPayoutMethodContract(payable(address(publisherPayoutMethod)));
        vm.stopBroadcast();
    }
}