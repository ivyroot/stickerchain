// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import "../IStickerObjective.sol";


// Example Objective which requires payment

contract PaidObjective is IStickerObjective, Ownable {
    address immutable public stickerChain;
    string public url;
    string public name;
    uint private fee;

    constructor(address _stickerChain, string memory _name, string memory _url, address _initialAdmin, uint _fee)
    Ownable(_initialAdmin)
    {
        stickerChain = _stickerChain;
        url = _url;
        name = _name;
        fee = _fee;
    }

    function owner() public view override(Ownable, IStickerObjective) returns (address) {
        return Ownable.owner();
    }

    function feeRecipient() external view override returns (address) {
        return owner();
    }

    function placeCount() external pure override returns (uint) {
        return 0;
    }

    function placeList() external pure override returns (uint[] memory) {
        return new uint[](0);
    }

    function costOfSlaps(address, FreshSlap[] calldata slaps) external view override
    returns (address, uint, address) {
        uint calculatedCost = fee * slaps.length;
        return (address(0), calculatedCost, owner());
    }

    // accept all slaps and do nothing
    function slapInObjective(address, FreshSlap[] calldata slaps) external payable override
    returns (uint[] memory includedSlapIds) {
        if (msg.sender != stickerChain) {
            revert InvalidCaller();
        }
        uint[] memory slapIds = new uint[](slaps.length);
        for (uint i = 0; i < slaps.length; i++) {
            slapIds[i] = slaps[i].slapId;
        }
        return slapIds;
    }
}