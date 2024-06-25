// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;


interface IPaymentMethod {

    event CoinAdded(address indexed coin, uint indexed coinId);
    event CoinBanned(address indexed coin, uint indexed coinId);

    // list payment methods
    function getPaymentMethod(uint _paymentMethodId) external view returns (address);
    function getIdOfPaymentMethod(address _coinAddress) external view returns (uint);

    // charge an address using a payment method
    function addressCanPay(uint _paymentMethodId, address _address, uint _amount) external view returns (bool);
    function chargeAddressForPayment(uint _paymentMethodId, address _address, uint _amount) external returns (bool);

    // add a payment method, self-serve
    function addNewCoinFee() external view returns (uint);
    function addNewCoin(address _coinAddress) external payable returns (bool);

    // add a payment method, admin
    function importCoin(address _coinAddress) external;

    // set new coin fee, admin
    function setAddNewCoinFee(uint _fee) external;

}