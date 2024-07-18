pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerChain.sol";
import "../src/PayoutMethod.sol";


contract DeployObjectivePayoutMethod is Script {
    function run() external {
        address payable stickerChainContractAddress = payable(vm.envAddress('STICKER_CHAIN_CONTRACT'));
        require(stickerChainContractAddress != address(0), 'DeployObjectivePayoutMethod: STICKER_CHAIN_CONTRACT not set');
        StickerChain stickerChain = StickerChain(stickerChainContractAddress);
        vm.startBroadcast();
        PayoutMethod objectivePayoutMethod = new PayoutMethod(address(stickerChain),  address(tx.origin));
        stickerChain.setObjectivePayoutMethodContract(payable(address(objectivePayoutMethod)));
        vm.stopBroadcast();
    }
}