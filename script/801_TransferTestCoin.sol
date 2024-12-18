pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/coins/TestCoin.sol";

contract TransferTestCoin is Script {
    function run(address recipient, uint256 amount) external {
        address payable testCoinContractAddress = payable(vm.envAddress('NYC_PAYMENT_COIN_ADDRESS'));
        require(testCoinContractAddress != address(0), 'TransferTestCoin: NYC_PAYMENT_COIN_ADDRESS not set');
        TestCoin testCoin = TestCoin(testCoinContractAddress);

        vm.startBroadcast();
        testCoin.transfer(recipient, amount);
        vm.stopBroadcast();
    }
}
