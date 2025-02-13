pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";


contract TransferTrialTest is Script {
    function run() external {
        address recipientAddress = vm.envAddress('RECIPIENT_ADDRESS');
        uint256 amount = vm.envUint('TRANSFER_AMOUNT');
        require(recipientAddress != address(0), 'TransferTrialTest: RECIPIENT_ADDRESS not set');
        vm.startBroadcast();
        payable(recipientAddress).transfer(amount);
        vm.stopBroadcast();
    }
}
