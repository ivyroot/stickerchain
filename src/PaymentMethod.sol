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

    event AdminTransferFailure(address indexed recipient, uint amount);

    error PaymentMethodNotAllowed();
    error AddressNotAllowed();
    error IncorrectFeePayment();
    error CoinAlreadyExists();

    constructor(address _feeRecipient, uint _addNewCoinFee) Ownable(msg.sender) {
        adminFeeRecipient = _feeRecipient;
        addNewCoinFee = _addNewCoinFee;
    }

    function getPaymentMethod(uint _paymentMethodId) public view returns (IERC20 coin) {
        address _coinAddress = coins[_paymentMethodId];
        if (bannedCoins[_coinAddress]) {
            return coin;
        }
        coin = IERC20(_coinAddress);
    }

    function getPaymentMethods(uint _offset, uint _count) external view returns (IERC20[] memory) {
        if (_offset >= coinCount) {
            return new IERC20[](0);
        }
        uint max = _offset + _count;
        if (max > coinCount) {
            max = coinCount;
        }
        IERC20[] memory _coins = new IERC20[](max - _offset);
        for (uint i = _offset; i < max; i++) {
            _coins[i - _offset] = getPaymentMethod(i);
        }
        return _coins;
    }

    function getIdOfPaymentMethod(address _coinAddress) public view returns (uint) {
        if (bannedCoins[_coinAddress]) {
            return 0;
        }
        return coinsLookup[_coinAddress];
    }

    function addressCanPay(uint _paymentMethodId, address _address, address _recipient, uint _amount) public view
        returns (bool) {
        IERC20 _coin = getPaymentMethod(_paymentMethodId);
        if (address(_coin) == address(0)) {
            return false;
        }
        uint accountAllowance = _coin.allowance(_address, _recipient);
        return accountAllowance >= _amount;
    }

    function chargeAddressForPayment(uint _paymentMethodId, address _address, address _recipient, uint _amount) public
        returns (bool) {
        IERC20 _coin = getPaymentMethod(_paymentMethodId);
        if (address(_coin) == address(0)) {
            revert PaymentMethodNotAllowed();
        }
        return _coin.transferFrom(_address, _recipient, _amount);
    }

    // public function to add coin
    function addNewCoin(address _coinAddress) public payable returns (uint) {
        if (bannedAddresses[msg.sender]) {
            revert AddressNotAllowed();
        }
        if (msg.value != addNewCoinFee) {
            revert IncorrectFeePayment();
        }
        (bool success,) = adminFeeRecipient.call{value: msg.value}("");
        if (!success) {
            emit AdminTransferFailure(adminFeeRecipient, msg.value);
        }
        return _addNewCoin(_coinAddress);
    }

    // admin function to add coin
    function importCoin(address _coinAddress) public onlyOwner returns (uint) {
        return _addNewCoin(_coinAddress);
    }

    function _addNewCoin(address _coinAddress) private returns (uint) {
        if (coinsLookup[_coinAddress] != 0) {
            revert CoinAlreadyExists();
        }
        coinCount++;
        coins[coinCount] = _coinAddress;
        coinsLookup[_coinAddress] = coinCount;
        emit CoinAdded(_coinAddress, coinCount);
        return coinCount;
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
            if (_undoBan) {
                emit CoinUnbanned(_coins[i], coinsLookup[_coins[i]]);
            } else {
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