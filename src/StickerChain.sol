// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import {StickerDesign} from "./StickerDesigns.sol";
import "block-places/BlockPlaces.sol";
import "forge-std/console.sol";

struct Slap {
    uint256 slapId;
    uint256 stickerId;
    uint256 placeId;
    uint256 height;
    uint256 slappedAt;
    uint8 size;
    address player;
}

struct StoredSlap {
    uint256 placeId;
    uint256 height;
    uint256 stickerId;
    uint256 slappedAt;
    uint8 size;
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
    uint256 slapCount;
    mapping (uint256 => uint256) slaps;
}

contract StickerChain is Ownable, ERC721A {
    event StickerSlapped(uint256 indexed placeId, uint256 indexed stickerId, address indexed player, uint8 size);

    error InvalidPlaceId(uint256 placeId);
    error InvalidStart();

    uint256 public slapFee;

    mapping (uint256 => StoredSlap) private _slaps;
    mapping (uint256 => StoredPlace) private _board;

    constructor(uint _initialSlapFee) Ownable(msg.sender) ERC721A("StickerChain", "SLAP")  {
        slapFee = _initialSlapFee;
    }

    function getPlace(uint _placeId) external view returns (Place memory) {
        (bool isValid, uint lng, uint lngDecimal, uint lat, uint latDecimal) = BlockPlaces.blockPlaceFromPlaceId(_placeId);
        if (!isValid) {
            revert InvalidPlaceId(_placeId);
        }
        Place memory place = Place({
            placeId: _placeId,
            lng: lng,
            lngDecimal: lngDecimal,
            lat: lat,
            latDecimal: latDecimal,
            slap: _board[_placeId].slaps[1],
            slapCount: _board[_placeId].slapCount
        });
        return place;
    }

    function getPlaces(uint[] calldata _placeIds) external view returns (Place[] memory) {
        Place[] memory places = new Place[](_placeIds.length);
        for (uint i = 0; i < _placeIds.length; i++) {
            places[i] = this.getPlace(_placeIds[i]);
        }
        return places;

    }

    function getSlap(uint _slapId) external view returns (Slap memory) {
        StoredSlap memory storedSlap = _slaps[_slapId];
        Slap memory loadedSlap  = Slap({
            slapId: _slapId,
            stickerId: storedSlap.stickerId,
            placeId: storedSlap.placeId,
            height: storedSlap.height,
            slappedAt: storedSlap.slappedAt,
            size: storedSlap.size,
            player: storedSlap.player
        });
        return loadedSlap;
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
        (bool isValid, , , ,) = BlockPlaces.blockPlaceFromPlaceId(_placeId);
        if (!isValid) {
            revert InvalidPlaceId(_placeId);
        }
        console.log("GOT HERE 1");
        uint256 slapCount = _board[_placeId].slapCount;
        if (_offset >= slapCount) {
            return (0, new Slap[](0));
        }
        int256 start = int(slapCount) - int(_offset);

        if (start <= 0) {
            revert InvalidStart();
        }
        uint256 startUint = uint(start);
        int256 min = int(slapCount) - int(_offset) - int(_limit);
        uint256 minUint = min < 0 ? 0 : uint(min);
        uint256 length = startUint >= minUint ? startUint - minUint : 0;
        console.log("startUint", startUint);
        console.log("minUint", minUint);

        console.log("length", length);
        console.log("GOT HERE 2");
        if (length == 0) {
            return (0, new Slap[](0));
        }
        console.log("GOT HERE 2.5");

        Slap[] memory slaps = new Slap[](uint(length));
        for (uint i = uint(startUint); i >= minUint; i--) {
            uint256 slapId = _board[_placeId].slaps[i];
            StoredSlap memory storedSlap = _slaps[slapId];
            slaps[i] = Slap({
                slapId: slapId,
                stickerId: storedSlap.stickerId,
                placeId: storedSlap.placeId,
                height: storedSlap.height,
                slappedAt: storedSlap.slappedAt,
                size: storedSlap.size,
                player: storedSlap.player
            });
        }
        console.log("GOT HERE 3");
        return (length, slaps);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function slap(uint _placeId, uint _stickerId, uint8 size) external payable {
        require(msg.value >= slapFee, "StickerChain: insufficient funds");
        (bool isValid, , , ,) = BlockPlaces.blockPlaceFromPlaceId(_placeId);
        if (!isValid) {
            revert InvalidPlaceId(_placeId);
        }

        uint _slappedTokenId = _nextTokenId();
        uint _slapHeight = _board[_placeId].slapCount + 1;
        _mint(msg.sender, 1);

        _slaps[_slappedTokenId] = StoredSlap({
            placeId: _placeId,
            height: _slapHeight,
            stickerId: _stickerId,
            slappedAt: block.timestamp,
            size: size,
            player: msg.sender
        });
        _board[_placeId].slaps[_board[_placeId].slapCount] = _slappedTokenId;
        // if (size > 1) {
        //     // TODO write slap at all covered places
        //     uint x = 2;
        // }

        _board[_placeId].slapCount++;

        emit Transfer(msg.sender, address(this), _slappedTokenId);
    }

}