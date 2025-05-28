pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/PaymentMethod.sol";

contract AddCoin is Script {
    function run() external {
        address paymentMethodAddress = vm.envAddress("PAYMENT_METHOD_CONTRACT");
        require(
            paymentMethodAddress != address(0),
            "AddCoin: PAYMENT_METHOD_CONTRACT not set"
        );
        address coinAddress = vm.envAddress("NEW_COIN_ADDRESS");
        require(coinAddress != address(0), "AddCoin: NEW_COIN_ADDRESS not set");

        vm.startBroadcast();

        PaymentMethod paymentMethod = PaymentMethod(paymentMethodAddress);
        paymentMethod.importCoin(coinAddress);

        // Get and log the payment method ID
        uint256 paymentMethodId = paymentMethod.getIdOfPaymentMethod(
            coinAddress
        );
        console.log("Payment Method ID for coin:", paymentMethodId);

        vm.stopBroadcast();
    }
}
