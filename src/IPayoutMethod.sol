// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


interface IPayoutMethod {

    event FundsAdded(uint indexed paymentTypeId, address indexed recipient, uint amount);
    event FundsWithdrawn(uint indexed paymentTypeId, address indexed account, uint amount);
    event PaymentTypeAdminFeeSet(uint indexed paymentTypeId, uint feeBasisPoints);

    // the contract which owns this payout and sends funds to it
    function sourceContract() external view returns (address);

    // admin fee charged for each payment type in basis points
    function adminFee(uint _paymentTypeId) external view returns (uint);

    // deposit funds, can only be called by the source contract
    function deposit(uint _paymentTypeId, uint _amount, address _recipient, bool _protocolPayment) external payable;

    // withdraw funds, can only withdraw balances of msg.sender
    // funds will be sent to the recipient or msg.sender if recipient is address(0)
    function withdraw(uint[] calldata _paymentTypeIds, address _recipient) external;

    // public view balance function
    function balanceOf(address _account, uint _paymentTypeId) external view returns (uint);

}