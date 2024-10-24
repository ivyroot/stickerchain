pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/PaymentMethod.sol";


contract DeployPaymentMethods is Script {
    function run() external {
        address initialAdminAddress = vm.envAddress('INITIAL_ADMIN');
        vm.startBroadcast();
        new PaymentMethod(initialAdminAddress, 50000000000000);
        vm.stopBroadcast();
    }
}