// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TestCoin is ERC20 {
    constructor(address admin) ERC20("TestCoin", "TEST") {
        _mint(admin, 1_000_000 * 10**decimals());
    }
}
