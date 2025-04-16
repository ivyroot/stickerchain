// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPaymentMethod} from "./IPaymentMethod.sol";


contract PaymentMethod is Ownable, IPaymentMethod {
    mapping (uint => address) private coins;
    mapping (address => uint) private coinsLookup;
    mapping (address => bool) public bannedCoins;
    mapping (address => bool) public bannedAddresses;
    uint public coinCount;
    uint public addNewCoinFee;
    address public operator;
    address public adminFeeRecipient;

    error InvalidPaymentMethodId();
    error PaymentMethodNotAllowed();
    error AddressNotAllowed();
    error IncorrectFeePayment();
    error CoinAlreadyExists();

    modifier onlyOperator() {
        if (msg.sender != operator) {
            revert AddressNotAllowed();
        }
        _;
    }

    constructor(address _initialAdmin, uint _addNewCoinFee) Ownable(_initialAdmin) {
        adminFeeRecipient = _initialAdmin;
        operator = _initialAdmin;
        addNewCoinFee = _addNewCoinFee;
    }

    function getPaymentMethod(uint _paymentMethodId) public view returns (IERC20 coin) {
        if (_paymentMethodId == 0) {
            revert InvalidPaymentMethodId();
        }
        address _coinAddress = coins[_paymentMethodId];
        if (bannedCoins[_coinAddress]) {
            return coin;
        }
        coin = IERC20(_coinAddress);
    }

    function getPaymentMethods(uint _paymentMethodId, uint _count) external view returns (IERC20[] memory) {
        if (_paymentMethodId > coinCount) {
            return new IERC20[](0);
        }
        if (_count == 0 || _paymentMethodId + _count - 1 > coinCount) {
            _count = coinCount - _paymentMethodId + 1;
        }
        IERC20[] memory _coins = new IERC20[](_count);
        for (uint i = 0; i < _count; i++) {
            _coins[i] = getPaymentMethod(_paymentMethodId + i);
        }
        return _coins;
    }

    function getIdOfPaymentMethod(address _coinAddress) public view returns (uint) {
        if (bannedCoins[_coinAddress]) {
            return 0;
        }
        return coinsLookup[_coinAddress];
    }

    function addressCanPay(uint _paymentMethodId, address _address, uint _amount) public view
        returns (uint balanceNeeded, uint allowanceNeeded) {
        IERC20 _coin = getPaymentMethod(_paymentMethodId);
        if (address(_coin) == address(0)) {
            return (0, 0);
        }
        uint accountBalance = _coin.balanceOf(_address);
        uint accountAllowance = _coin.allowance(_address, msg.sender);
        balanceNeeded = _amount > accountBalance ? _amount - accountBalance : 0;
        allowanceNeeded = _amount > accountAllowance ? _amount - accountAllowance : 0;
    }

    // public function to add coin
    function addNewCoin(address _coinAddress) public payable returns (uint) {
        if (bannedAddresses[msg.sender]) {
            revert AddressNotAllowed();
        }
        if (msg.value != addNewCoinFee && msg.sender != operator) {
            revert IncorrectFeePayment();
        }
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


    function setAdminFeeRecipient(address _recipient) public onlyOwner {
        if (_recipient == address(0)) {
            revert AddressNotAllowed();
        }
        adminFeeRecipient = _recipient;
    }

    function setOperator(address _operator) public onlyOwner {
        operator = _operator;
    }

    function importCoin(address _coinAddress) public onlyOperator returns (uint) {
        return _addNewCoin(_coinAddress);
    }

    function setAddNewCoinFee(uint _fee) public onlyOperator {
        addNewCoinFee = _fee;
        emit AddNewCoinFeeChanged(_fee);
    }

    function banCoins(address[] memory _coins, bool _undoBan) public onlyOperator {
        for (uint i = 0; i < _coins.length; i++) {
            bannedCoins[_coins[i]] = !_undoBan;
            if (_undoBan) {
                emit CoinUnbanned(_coins[i], coinsLookup[_coins[i]]);
            } else {
                emit CoinBanned(_coins[i], coinsLookup[_coins[i]]);
            }
        }
    }

    function banAddresses(address[] memory _addresses, bool _undoBan) public onlyOperator {
        for (uint i = 0; i < _addresses.length; i++) {
            bannedAddresses[_addresses[i]] = !_undoBan;
            if (!_undoBan) {
                emit AddressBanned(_addresses[i]);
            } else {
                emit AddressUnbanned(_addresses[i]);
            }
        }
    }

    function transferAdminFees() external {
        payable(adminFeeRecipient).transfer(address(this).balance);
    }

}