pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/PaymentMethod.sol";


contract DeployPaymentMethods is Script {
    function run() external {
        vm.startBroadcast();
        new PaymentMethod(address(tx.origin), 50000000000000);
        vm.stopBroadcast();
    }
}