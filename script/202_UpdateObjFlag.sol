pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/objectives/FlagObjective.sol";
import "../src/coins/TestCoin.sol";

contract UpdateObjFlagFee is Script {
    function run() external {
        address flagContractAddress = vm.envAddress('FLAG_CONTRACT');
        require(flagContractAddress != address(0), 'UpdateObjFlagFee: FLAG_CONTRACT not set');

        address paymentCoinAddress = vm.envAddress('FLAG_PAYMENT_COIN_ADDRESS');
        require(paymentCoinAddress != address(0), 'UpdateObjFlagFee: FLAG_PAYMENT_COIN_ADDRESS not set');

        uint256 slapFee = 1 ether; // equivalent to 1 * 10**18

        FlagObjective flag = FlagObjective(flagContractAddress);

        vm.startBroadcast();
        flag.setSlapFee(paymentCoinAddress, slapFee);
        vm.stopBroadcast();
    }
}
