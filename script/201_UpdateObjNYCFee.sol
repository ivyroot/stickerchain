pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/objectives/NYC.sol";
import "../src/coins/TestCoin.sol";

contract UpdateObjNYCFee is Script {
    function run() external {
        address nycContractAddress = vm.envAddress('NYC_CONTRACT');
        require(nycContractAddress != address(0), 'UpdateObjNYCFee: NYC_CONTRACT not set');

        address paymentCoinAddress = vm.envAddress('NYC_PAYMENT_COIN_ADDRESS');
        require(paymentCoinAddress != address(0), 'UpdateObjNYCFee: NYC_PAYMENT_COIN_ADDRESS not set');

        // 1 token with 18 decimals
        uint256 slapFee = 1 ether; // equivalent to 1 * 10**18

        NYC nyc = NYC(nycContractAddress);

        vm.startBroadcast();
        nyc.setSlapFee(paymentCoinAddress, slapFee);
        vm.stopBroadcast();
    }
}
