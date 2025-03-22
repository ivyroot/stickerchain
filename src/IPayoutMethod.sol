// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


interface IPayoutMethod {
    // Note: address(0) is used as the coin address for chain native ETH

    event FundsAdded(address indexed recipient, address indexed coin, uint amount);
    event FundsWithdrawn(address indexed account, address indexed coin, uint amount);
    event PaymentTypeAdminFeeSet(address indexed coin, uint feeBasisPoints);

    // the contract which owns this payout and sends funds to it
    function sourceContract() external view returns (address);

    // admin fee charged for each payment type in basis points
    function adminFee(address _coin) external view returns (uint);

    // deposit funds, can only be called by the source contract
    function deposit(address _coin, uint _amount, address _recipient, bool _protocolPayment) external payable;

    // withdraw funds, any address can trigger transfer of funds due to any recipient
    function withdraw(address[] calldata _coins, address _recipient) external;

    // public view balance function
    function balanceOf(address _account, address _coin) external view returns (uint);

}