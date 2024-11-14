pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/coins/TestCoin.sol";
import "../src/PaymentMethod.sol";

contract DeployTestToken is Script {
    function run() external {
        address initialAdminAddress = vm.envAddress('INITIAL_ADMIN');
        require(initialAdminAddress != address(0), 'DeployTestToken: INITIAL_ADMIN not set');

        address paymentMethodAddress = vm.envAddress('PAYMENT_METHOD_CONTRACT');
        require(paymentMethodAddress != address(0), 'DeployTestToken: PAYMENT_METHOD_CONTRACT not set');

        vm.startBroadcast();

        TestCoin testCoin = new TestCoin(initialAdminAddress);

        PaymentMethod paymentMethod = PaymentMethod(paymentMethodAddress);
        paymentMethod.importCoin(address(testCoin));

        // Get and log the payment method ID
        uint256 paymentMethodId = paymentMethod.getIdOfPaymentMethod(address(testCoin));
        console.log("Payment Method ID for TestCoin:", paymentMethodId);

        vm.stopBroadcast();
    }
}
