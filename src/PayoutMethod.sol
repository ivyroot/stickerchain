// SPDX-License-Identifier: MIT
//
// payout method by ivyroot
//
//        x.com/ivyroot_zk
//
//        farcaster.xyz/ivyroot
//

pragma solidity ^0.8.26;
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPaymentMethod} from "./IPaymentMethod.sol";
import {IPayoutMethod} from "./IPayoutMethod.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuardTransient} from "openzeppelin-contracts/contracts/utils/ReentrancyGuardTransient.sol";
import "forge-std/console.sol";

contract PayoutMethod is IPayoutMethod, Ownable, ReentrancyGuardTransient {

    error OnlySourceContractAllowed(address);
    error InvalidPaymentAmount(uint256);
    error ERC20TransferFailed(address, uint256);
    error ETHTransferFailed(uint256);
    error InvalidFeeBasisPoints();
    error InvalidFeeRecipient();

    address public immutable override sourceContract;

    mapping(address => uint) public override adminFee;
    mapping(address => address) public adminFeeRecipient;

    mapping(address account => mapping(address coin => uint256)) public override balanceOf;

    constructor(address _sourceContract, address _initialAdmin) Ownable(_initialAdmin) {
        sourceContract = _sourceContract;
        adminFeeRecipient[address(0)] = _initialAdmin;
    }

    // deposit funds, can only be called by the source contract
    function deposit(address _coin, uint _amount, address _recipient, bool _protocolPayment) external payable override {
        if (msg.sender != sourceContract) revert OnlySourceContractAllowed(msg.sender);
        if (_coin == address(0) && msg.value != _amount) {
            revert InvalidPaymentAmount(msg.value);
        }
        uint _adminFee = _protocolPayment ? 5000 : adminFee[_coin];
        address _adminFeeRecipient = adminFeeRecipient[_coin];
        if (_adminFee > 0 && _adminFeeRecipient != address(0)) {
            uint fee = (_amount * _adminFee) / 10000;
            balanceOf[_adminFeeRecipient][_coin] += fee;
            _amount -= fee;
        }
        balanceOf[_recipient][_coin] += _amount;
        emit FundsAdded(_recipient, _coin, _amount);
    }

    // withdraw funds - any address can trigger transfer of funds due to any recipient
    function withdraw(address[] calldata _coins, address _recipient) external nonReentrant override {
        if (_recipient == address(0)) {
            _recipient = msg.sender;
        }
        uint _paymentTypeCount = _coins.length;
        for (uint i = 0; i < _paymentTypeCount; i++) {
            address _coin = _coins[i];
            uint _amount = balanceOf[_recipient][_coin];
            if (_amount > 0) {
                balanceOf[_recipient][_coin] = 0;
                if (_coin == address(0)) {
                    (bool sent, ) = payable(_recipient).call{value: _amount}("");
                    if (!sent) {
                        revert ETHTransferFailed(_amount);
                    }
                } else {
                    bool paid = IERC20(_coin).transfer(_recipient, _amount);
                    if (!paid) {
                        revert ERC20TransferFailed(_coin, _amount);
                    }
                }
                emit FundsWithdrawn(_recipient, _coin, _amount);
            }
        }
    }

    // owner only function to set fee for payment type
    function setAdminFee(address _coin, uint _feeBasisPoints, address _feeRecipient) external onlyOwner {
        if (_feeBasisPoints > 10000) {
            revert InvalidFeeBasisPoints();
        }
        if (_feeRecipient == address(0)) {
            revert InvalidFeeRecipient();
        }
        adminFee[_coin] = _feeBasisPoints;
        adminFeeRecipient[_coin] = _feeRecipient;
        emit PaymentTypeAdminFeeSet(_coin, _feeBasisPoints);
    }

}