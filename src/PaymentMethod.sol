// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPaymentMethod} from "./IPaymentMethod.sol";


contract PaymentMethod is Ownable, IPaymentMethod {
    mapping (uint => address) public coins;
    mapping (address => uint) public coinsLookup;
    mapping (address => bool) public bannedCoins;
    mapping (address => bool) public bannedAddresses;
    uint public coinCount;
    uint public addNewCoinFee;
    address public adminFeeRecipient;

    error PaymentMethodNotAllowed();
    error AddressNotAllowed();
    error IncorrectFeePayment();
    error CoinAlreadyExists();

    constructor(address _feeRecipient, uint _addNewCoinFee) Ownable(msg.sender) {
        adminFeeRecipient = _feeRecipient;
        addNewCoinFee = _addNewCoinFee;
    }

    function _isBannedAccount(address _address) private view returns (bool) {
        return bannedAddresses[_address];
    }

    function _paymentMethodIdIsValid(uint _paymentMethodId) private view returns (bool) {
        address _coinAddress = coins[_paymentMethodId];
        if (bannedCoins[_coinAddress]) {
            return false;
        }
        return _paymentMethodId <= coinCount && _paymentMethodId > 0;
    }

    function getPaymentMethod(uint _paymentMethodId) public view returns (address) {
        if (!_paymentMethodIdIsValid(_paymentMethodId)) {
            return address(0);
        }
        return coins[_paymentMethodId];
    }

    function getIdOfPaymentMethod(address _coinAddress) public view returns (uint) {
        if (bannedCoins[_coinAddress]) {
            return 0;
        }
        return coinsLookup[_coinAddress];
    }

    function addressCanPay(uint _paymentMethodId, address _address, uint _amount) public view
        returns (bool) {
        if (!_paymentMethodIdIsValid(_paymentMethodId)) {
            return false;
        }
        IERC20 _coin = IERC20(coins[_paymentMethodId]);
        uint accountAllowance = _coin.allowance(_address, address(this));
        return accountAllowance >= _amount;
    }

    function chargeAddressForPayment(uint _paymentMethodId, address _address, uint _amount) public
        returns (bool) {
        if (!_paymentMethodIdIsValid(_paymentMethodId)) {
            revert PaymentMethodNotAllowed();
        }
        IERC20 _coin = IERC20(coins[_paymentMethodId]);
        return _coin.transferFrom(_address, msg.sender, _amount);
    }

    function addNewCoin(address _coinAddress) public payable returns (bool) {
        if (_isBannedAccount(msg.sender)) {
            revert AddressNotAllowed();
        }
        if (msg.value != addNewCoinFee) {
            revert IncorrectFeePayment();
        }
        (bool success,) = adminFeeRecipient.call{value: msg.value}("");
        if (success) {
            _addNewCoin(_coinAddress);
            return true;
        }else {
            return false;
        }
    }

    // admin function to add coin
    function importCoin(address _coinAddress) public onlyOwner {
        _addNewCoin(_coinAddress);
    }

    function _addNewCoin(address _coinAddress) private {
        if (coinsLookup[_coinAddress] != 0) {
            revert CoinAlreadyExists();
        }
        coinCount++;
        coins[coinCount] = _coinAddress;
        coinsLookup[_coinAddress] = coinCount;
        emit CoinAdded(_coinAddress, coinCount);
    }


    // admin function to change fee
    function setAddNewCoinFee(uint _fee) public onlyOwner {
        addNewCoinFee = _fee;
    }

    // admin function to set admin fee recipient. cannot be zero address
    function setAdminFeeRecipient(address _recipient) public onlyOwner {
        if (_recipient == address(0)) {
            revert AddressNotAllowed();
        }
        adminFeeRecipient = _recipient;
    }

    // admin function to set banned coins
    function banCoins(address[] memory _coins, bool _undoBan) public onlyOwner {
        for (uint i = 0; i < _coins.length; i++) {
            bannedCoins[_coins[i]] = !_undoBan;
            if (!_undoBan) {
                emit CoinBanned(_coins[i], coinsLookup[_coins[i]]);
            }
        }
    }

    // admin function set and unset banned addresses
    function banAddresses(address[] memory _addresses, bool _undoBan) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            bannedAddresses[_addresses[i]] = !_undoBan;
        }
    }

}