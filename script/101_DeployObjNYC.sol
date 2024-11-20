pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/objectives/NYC.sol";
import "../src/StickerObjectives.sol";

contract DeployObjectiveNYC is Script {
    function run() external {
        address initialAdminAddress = vm.envAddress('INITIAL_ADMIN');
        address payable stickerChainContractAddress = payable(vm.envAddress('STICKER_CHAIN_CONTRACT'));
        address objectivesContractAddress = vm.envAddress('OBJECTIVES_CONTRACT');
        require(stickerChainContractAddress != address(0), 'DeployObjNYC: STICKER_CHAIN_CONTRACT not set');
        require(objectivesContractAddress != address(0), 'DeployObjNYC: OBJECTIVES_CONTRACT not set');

        vm.startBroadcast();
        // Deploy NYC and capture its address
        NYC nyc = new NYC(
            stickerChainContractAddress,
            initialAdminAddress,
            "NYC",
            "NYC",
            "https://stickerchain.xyz/objectives/NYC"
        );

        // Get the StickerObjectives contract and add the new NYC objective
        StickerObjectives objectives = StickerObjectives(objectivesContractAddress);
        objectives.addNewObjective(IStickerObjective(address(nyc)));

        vm.stopBroadcast();
    }
}