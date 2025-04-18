// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


interface IPaymentMethod {

    event CoinAdded(address indexed coin, uint indexed coinId);
    event CoinBanned(address indexed coin, uint indexed coinId);
    event CoinUnbanned(address indexed coin, uint indexed coinId);
    event AddNewCoinFeeChanged(uint newFee);
    event AddressBanned(address indexed bannedAddress);
    event AddressUnbanned(address indexed unbannedAddress);

    // list payment methods
    function getPaymentMethod(uint _paymentMethodId) external view returns (IERC20);
    function getPaymentMethods(uint _offset, uint _count) external view returns (IERC20[] memory);
    function getIdOfPaymentMethod(address _coinAddress) external view returns (uint);

    // check if an address can pay for something
    function addressCanPay(uint _paymentMethodId, address _address, uint _amount) external view returns (uint balanceNeeded, uint allowanceNeeded);

    // add a payment method, self-serve
    function addNewCoinFee() external view returns (uint);
    function addNewCoin(address _coinAddress) external payable returns (uint);

    // add a payment method, admin
    function importCoin(address _coinAddress) external returns (uint);

    // set new coin fee, admin
    function setAddNewCoinFee(uint _fee) external;

}