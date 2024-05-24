// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {StickerDesign} from "./StickerDesigns.sol";
import "block-places/BlockPlaces.sol";

struct Slap {
    uint256 slapId;
    uint256 stickerId;
    uint256 placeId;
    uint256 slappedAt;
    address player;
}

struct StoredSlap {
    uint256 stickerId;
    uint256 placeId;
    uint256 slappedAt;
    address player;
}

struct Place {
    uint256 placeId;
    uint256 lng;
    uint256 lngDecimal;
    uint256 lat;
    uint256 latDecimal;
    uint256 slap;
    uint256 slapCount;
}

struct StoredPlace {
    uint256 slap;
    uint256 slapCount;
    uint256 firstSlap;
}

contract StickerChain is Ownable {
    uint256 public slapFee;

    mapping (uint256 => StoredSlap) private _slaps;
    mapping (uint256 => StoredPlace) private _board;
    mapping (uint256 => mapping (uint256 => StoredSlap)) private _boardSlapEpochs;

    constructor(uint _reputationFee) Ownable(msg.sender) {
        slapFee = _reputationFee;
    }

    function getSlap(uint _slapId) external view returns (Slap memory) {
        StoredSlap memory storedSlap = _slaps[_slapId];
        Slap memory slap = Slap({
            slapId: _slapId,
            stickerId: storedSlap.stickerId,
            placeId: storedSlap.placeId,
            slappedAt: storedSlap.slappedAt,
            player: storedSlap.player
        });
        return slap;
    }
    function getSlaps(uint[] calldata _slapIds) external view returns (Slap[] memory) {
        Slap[] memory slaps = new Slap[](_slapIds.length);
        for (uint i = 0; i < _slapIds.length; i++) {
            slaps[i] = this.getSlap(_slapIds[i]);
        }
        return slaps;
    }

    // returns Slaps at Place starting from most recent and going back in time
    function getPlaceSlaps(uint _placeId, uint _offset, uint _limit) external view returns (uint total, Slap[] memory) {
        uint256[] memory slapEpochs = _boardSlapEpochs[_placeId];
        Slap[] memory slaps = new Slap[](slapEpochs.length);
        for (uint i = 0; i < slapEpochs.length; i++) {
            slaps[i] = this.getSlap(slapEpochs[i]);
        }
        return slaps;
    }



}