// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IStickerObjective} from "../IStickerObjective.sol";


//      _    _   ___     _______
//     | |  | \ | \ \   / / ____|
//    / __) |  \| |\ \_/ / |
//    \__ \ |   ` | \   /| |
//    (   / | |\  |  | | | |____
//     |_|  |_| \_|  |_|  \_____|


contract NYC is ERC20, IStickerObjective {
    uint256 immutable public genesis;

    constructor(string memory _name, string memory _ticker) ERC20(_name, _ticker) {
        genesis = block.timestamp;
    }


}