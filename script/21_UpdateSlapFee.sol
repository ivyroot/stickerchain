pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerChain.sol";


contract UpdateSlapFee is Script {
    function run() external {
        address payable stickerChainContractAddress = payable(vm.envAddress('STICKER_CHAIN_CONTRACT'));
        require(stickerChainContractAddress != address(0), 'UpdateSlapFee: STICKER_CHAIN_CONTRACT not set');
        uint256 slapFee = vm.envUint('SLAP_FEE');
        require(slapFee > 0, 'UpdateSlapFee: SLAP_FEE not set');
        StickerChain stickerChain = StickerChain(stickerChainContractAddress);
        vm.startBroadcast();
        stickerChain.setSlapFee(slapFee);
        vm.stopBroadcast();
    }
}
