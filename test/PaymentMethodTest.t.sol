// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import "forge-std/Test.sol";
import "../src/PaymentMethod.sol";

// Test ERC20 token for testing payment methods
contract TestCoin is ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract PaymentMethodTest is Test {
    PaymentMethod paymentMethod;
    TestCoin testCoin1;
    TestCoin testCoin2;
    uint256 public addNewCoinFee = 0.001 ether;
    address adminAddress = address(this);
    address externalUser = address(0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97);

    receive() external payable {}
    fallback() external payable {}

    function setUp() public {
        vm.deal(adminAddress, 20 ether);
        vm.deal(externalUser, 20 ether);

        paymentMethod = new PaymentMethod(adminAddress, addNewCoinFee);
        testCoin1 = new TestCoin("TestCoin1", "TC1");
        testCoin2 = new TestCoin("TestCoin2", "TC2");
    }

    function testAdminCanImportCoin() public {
        uint256 coinId = paymentMethod.importCoin(address(testCoin1));
        assertEq(coinId, 1);
        assertEq(paymentMethod.coinCount(), 1);

        // Verify coin was added correctly
        IERC20 retrievedCoin = paymentMethod.getPaymentMethod(coinId);
        assertEq(address(retrievedCoin), address(testCoin1));
    }

    function testExternalUserCanAddCoin() public {
        vm.startPrank(externalUser);
        uint256 initialBalance = externalUser.balance;

        uint256 coinId = paymentMethod.addNewCoin{value: addNewCoinFee}(address(testCoin1));
        assertEq(coinId, 1);
        assertEq(paymentMethod.coinCount(), 1);

        // Verify fee was paid
        assertEq(externalUser.balance, initialBalance - addNewCoinFee);

        // Verify coin was added correctly
        IERC20 retrievedCoin = paymentMethod.getPaymentMethod(coinId);
        assertEq(address(retrievedCoin), address(testCoin1));
        vm.stopPrank();
    }

    function testCannotAddSameCoinTwice() public {
        paymentMethod.importCoin(address(testCoin1));

        vm.expectRevert(abi.encodeWithSignature("CoinAlreadyExists()"));
        paymentMethod.importCoin(address(testCoin1));
    }

    function testGetPaymentMethodFields() public {
        // First import a coin
        uint256 coinId = paymentMethod.importCoin(address(testCoin1));

        // Get the payment method details
        IERC20 retrievedCoin = paymentMethod.getPaymentMethod(coinId);

        // Verify all fields match
        assertEq(address(retrievedCoin), address(testCoin1));
        assertEq(ERC20(address(retrievedCoin)).name(), "TestCoin1");
        assertEq(ERC20(address(retrievedCoin)).symbol(), "TC1");
        assertEq(ERC20(address(retrievedCoin)).decimals(), 18); // ERC20 default decimals
    }

    function testGetPaymentMethodsArray() public {
        // Import two coins
        uint256 coinId1 = paymentMethod.importCoin(address(testCoin1));
        uint256 coinId2 = paymentMethod.importCoin(address(testCoin2));

        assertEq(coinId1, 1);
        assertEq(coinId2, 2);

        // Get all payment methods
        IERC20[] memory coins = paymentMethod.getPaymentMethods(0,100);

        // Verify array length
        assertEq(coins.length, 2);

        // Verify all coins in array match
        assertEq(address(coins[0]), address(testCoin1));
        assertEq(ERC20(address(coins[0])).name(), "TestCoin1");
        assertEq(ERC20(address(coins[0])).symbol(), "TC1");
        assertEq(ERC20(address(coins[0])).decimals(), 18);

        assertEq(address(coins[1]), address(testCoin2));
        assertEq(ERC20(address(coins[1])).name(), "TestCoin2");
        assertEq(ERC20(address(coins[1])).symbol(), "TC2");
        assertEq(ERC20(address(coins[1])).decimals(), 18);

        // Verify getIdOfPaymentMethod returns correct IDs
        assertEq(paymentMethod.getIdOfPaymentMethod(address(testCoin1)), 1);
        assertEq(paymentMethod.getIdOfPaymentMethod(address(testCoin2)), 2);
    }

}
