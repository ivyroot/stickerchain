// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract StickerDesigns is ERC721A, Ownable {
    constructor() ERC721A("StickerDesignz", "STKRS-TEST-DEV") Ownable(msg.sender) {}

    function mint(uint256 quantity) external payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }
}
