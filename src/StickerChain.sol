// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import {StickerDesign, StickerDesigns} from "./StickerDesigns.sol";
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
    event StickerSlapped(uint256 indexed placeId, uint256 indexed stickerId, address indexed player, uint256 slapId, uint8 size);

    error InvalidPlaceId(uint256 placeId);
    error PlayerIsBanned();
    error InvalidStart();

    StickerDesigns immutable public stickerDesignsContract;

    uint256 public slapFee;

    mapping (uint256 => StoredSlap) private _slaps;
    mapping (uint256 => StoredPlace) private _board;

    mapping (address => bool) private _bannedPlayers;

    constructor(uint _initialSlapFee, address payable _stickerDesignsAddress) Ownable(msg.sender) ERC721A("StickerChain", "SLAP")  {
        slapFee = _initialSlapFee;
        stickerDesignsContract = StickerDesigns(_stickerDesignsAddress);
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
        uint256 slapCount = _board[_placeId].slapCount;
        if (_offset >= slapCount) {
            return (0, new Slap[](0));
        }
        int256 start = int(slapCount) - int(_offset);

        if (start <= 0) {
            revert InvalidStart();
        }
        uint256 startUint = uint(start);
        uint256 calculatedLimit = _limit == 0 ? startUint : _limit;
        int256 min = int(slapCount) - int(_offset) - int(calculatedLimit);
        uint256 minUint = min < 0 ? 0 : uint(min);
        uint256 length = startUint >= minUint ? startUint - minUint : 0;
        if (length == 0) {
            return (0, new Slap[](0));
        }
        Slap[] memory slaps = new Slap[](uint(length));
        uint resultIndex = 0;
        for (uint i = uint(startUint); i > minUint; i--) {
            uint256 slapId = _board[_placeId].slaps[i];
            StoredSlap memory storedSlap = _slaps[slapId];
            slaps[resultIndex] = Slap({
                slapId: slapId,
                stickerId: storedSlap.stickerId,
                placeId: storedSlap.placeId,
                height: storedSlap.height,
                slappedAt: storedSlap.slappedAt,
                size: storedSlap.size,
                player: storedSlap.player
            });
            resultIndex++;
        }
        return (length, slaps);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function nextSlapId() external view returns (uint256) {
        return _nextTokenId();
    }

    function slap(uint _placeId, uint _stickerId, uint8 size) external payable {
        if (_bannedPlayers[msg.sender]) {
            revert PlayerIsBanned();
        }
        require(msg.value >= slapFee, "StickerChain: insufficient funds");
        (bool isValid, , , ,) = BlockPlaces.blockPlaceFromPlaceId(_placeId);
        if (!isValid) {
            revert InvalidPlaceId(_placeId);
        }
        stickerDesignsContract.assertValidStickerDesign(_stickerId);

        uint _slappedTokenId = _nextTokenId();
        _mint(msg.sender, 1);

        uint _originSlapHeight = _board[_placeId].slapCount + 1;
        _slaps[_slappedTokenId] = StoredSlap({
            placeId: _placeId,
            height: _originSlapHeight,
            stickerId: _stickerId,
            slappedAt: block.timestamp,
            size: size,
            player: msg.sender
        });
        if (size == 1) {
            _board[_placeId].slaps[_originSlapHeight] = _slappedTokenId;
            _board[_placeId].slapCount = _originSlapHeight;
        } else {
            // write slap to all covered places
            uint _localSlapHeight;
            uint[] memory placeIds = BlockPlaces.placeIdsInSquare(_placeId, size);
            for (uint i = 0; i < placeIds.length; i++) {
                _localSlapHeight = _board[placeIds[i]].slapCount + 1;
                _board[placeIds[i]].slaps[_localSlapHeight] = _slappedTokenId;
                _board[placeIds[i]].slapCount = _localSlapHeight;
            }
        }
        emit StickerSlapped(_placeId, _stickerId, msg.sender, _slappedTokenId, size);
        emit Transfer(msg.sender, address(this), _slappedTokenId);
    }


    // admin methods
    function setSlapFee(uint _newSlapFee) external onlyOwner {
        slapFee = _newSlapFee;
    }

    function setPlayersBanned(address[] calldata _players, bool _banned) external onlyOwner {
        for (uint i = 0; i < _players.length; i++) {
            _bannedPlayers[_players[i]] = _banned;
        }
    }

}