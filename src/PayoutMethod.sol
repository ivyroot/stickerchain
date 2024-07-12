// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPaymentMethod} from "./IPaymentMethod.sol";
import {IPayoutMethod} from "./IPayoutMethod.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuardTransient} from "openzeppelin-contracts/contracts/utils/ReentrancyGuardTransient.sol";
import "forge-std/console.sol";

contract PayoutMethod is IPayoutMethod, Ownable, ReentrancyGuardTransient {

    address public override sourceContract;

    IPaymentMethod public immutable paymentMethodContract;

    mapping(uint => uint) public override adminFee;
    mapping(uint => address) public adminFeeRecipient;

    mapping(address account => mapping(uint256 paymentMethod => uint256)) public override balanceOf;

    constructor(address _paymentMethodContract, address _initialAdmin) Ownable(_initialAdmin) {
        paymentMethodContract = IPaymentMethod(_paymentMethodContract);
    }

    // deposit funds, can only be called by the source contract
    function deposit(uint _paymentTypeId, uint _amount, address _recipient, bool _protocolPayment) external payable override {
        require(msg.sender == sourceContract, "PayoutMethod: only source contract can deposit");
        if (_paymentTypeId == 0 && msg.value != _amount) {
            revert("PayoutMethod: msg.value must be equal to amount for paymentTypeId 0");
        }
        uint _adminFee = _protocolPayment ? 5000 : adminFee[_paymentTypeId];
        address _adminFeeRecipient = adminFeeRecipient[_paymentTypeId];
        if (_adminFee > 0 && _adminFeeRecipient != address(0)) {
            uint fee = (_amount * _adminFee) / 10000;
            balanceOf[_adminFeeRecipient][_paymentTypeId] += fee;
            _amount -= fee;
        }
        balanceOf[_recipient][_paymentTypeId] += _amount;
        emit FundsAdded(_paymentTypeId, _recipient, _amount);
    }

    // withdraw funds, can only withdraw balances of msg.sender
    // funds will be sent to the recipient or msg.sender if recipient is address(0)
    function withdraw(uint[] calldata _paymentTypeIds, address _recipient) external nonReentrant override {
        if (_recipient == address(0)) {
            _recipient = msg.sender;
        }
        uint _paymentTypeCount = _paymentTypeIds.length;
        for (uint i = 0; i < _paymentTypeCount; i++) {
            uint _paymentTypeId = _paymentTypeIds[i];
            uint _amount = balanceOf[msg.sender][_paymentTypeId];
            if (_amount > 0) {
                balanceOf[msg.sender][_paymentTypeId] = 0;
                if (_paymentTypeId == 0) {
                    (bool sent, ) = payable(_recipient).call{value: _amount}("");
                    if (!sent) {
                        revert("PayoutMethod: failed to send ether");
                    }
                } else {
                    // TODO handle case where token is banned, pending payouts should not be locked
                    IERC20 _paymentMethod = paymentMethodContract.getPaymentMethod(_paymentTypeId);
                    bool paid = _paymentMethod.transfer(_recipient, _amount);
                    if (!paid) {
                        revert("PayoutMethod: failed to send token");
                    }
                }
                emit FundsWithdrawn(_paymentTypeId, msg.sender, _amount);
            }
        }
    }

    // owner only function to set fee for payment type
    function setAdminFee(uint _paymentTypeId, uint _feeBasisPoints) external onlyOwner {
        require(_feeBasisPoints <= 10000, "PayoutMethod: fee must be <= 10000");
        adminFee[_paymentTypeId] = _feeBasisPoints;
        emit PaymentTypeAdminFeeSet(_paymentTypeId, _feeBasisPoints);
    }

}