pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerDesigns.sol";
import "../src/IPaymentMethod.sol";

contract DeployStickerDesigns is Script {
    function run() external {
        IPaymentMethod paymentMethodContractAddress = IPaymentMethod(payable(vm.envAddress('PAYMENT_METHOD_CONTRACT')));
        require(paymentMethodContractAddress != IPaymentMethod(address(0)), 'DeployStickerDesigns: PAYMENT_METHOD_CONTRACT not set');
        vm.startBroadcast();
        new StickerDesigns(paymentMethodContractAddress, address(tx.origin), 2000000000000000, 50000000000000);
        vm.stopBroadcast();
    }
}