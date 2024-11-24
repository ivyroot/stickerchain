pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/objectives/FlagObjective.sol";
import "../src/StickerObjectives.sol";

contract DeployObjectiveFlag is Script {
    function run() external {
        address initialAdminAddress = vm.envAddress('INITIAL_ADMIN');
        address payable stickerChainContractAddress = payable(vm.envAddress('STICKER_CHAIN_CONTRACT'));
        address objectivesContractAddress = vm.envAddress('OBJECTIVES_CONTRACT');
        require(stickerChainContractAddress != address(0), 'DeployObjFlag: STICKER_CHAIN_CONTRACT not set');
        require(objectivesContractAddress != address(0), 'DeployObjFlag: OBJECTIVES_CONTRACT not set');

        vm.startBroadcast();

        // Deploy FlagObjective
        FlagObjective flag = new FlagObjective(
            stickerChainContractAddress,
            initialAdminAddress,
            "https://stickerchain.xyz/objectives/flag"
        );
        flag.setSlapFee(address(0), 0.0003 ether);

        // Get the StickerObjectives contract and add the new FlagObjective
        StickerObjectives objectives = StickerObjectives(objectivesContractAddress);
        objectives.addNewObjective(IStickerObjective(address(flag)));

        vm.stopBroadcast();
    }
}
