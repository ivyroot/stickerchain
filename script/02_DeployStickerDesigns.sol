pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/StickerDesigns.sol";
import "../src/IPaymentMethod.sol";

contract DeployStickerDesigns is Script {
    function run() external {
        address initialAdminAddress = vm.envAddress('INITIAL_ADMIN');
        IPaymentMethod paymentMethodContractAddress = IPaymentMethod(payable(vm.envAddress('PAYMENT_METHOD_CONTRACT')));
        require(paymentMethodContractAddress != IPaymentMethod(address(0)), 'DeployStickerDesigns: PAYMENT_METHOD_CONTRACT not set');
        vm.startBroadcast();
        new StickerDesigns(paymentMethodContractAddress, initialAdminAddress, 2000000000000000, 50000000000000);
        vm.stopBroadcast();
    }
}