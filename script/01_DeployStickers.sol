pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerDesigns.sol";


contract DeployStickers is Script {
    function run() external {
        vm.startBroadcast();
        new StickerDesigns(address(tx.origin), 2000000000000000, 50000000000000);
        vm.stopBroadcast();
    }
}