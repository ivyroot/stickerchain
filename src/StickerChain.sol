// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import {IPaymentMethod} from "./IPaymentMethod.sol";
import {StickerDesign, StickerDesigns} from "./StickerDesigns.sol";
import "block-places/BlockPlaces.sol";
import "forge-std/console.sol";

struct Slap {
    uint256 slapId;
    uint256 stickerId;
    uint256 placeId;
    uint256 height;
    uint256 slappedAt;
    uint64 size;
    address player;
}

struct NewSlap {
    uint256 placeId;
    uint256 stickerId;
    uint64 size;
}

struct StoredSlap {
    uint256 placeId;
    uint256 height;
    uint256 stickerId;
    uint256 slappedAt;
    uint64 size;
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

struct PaymentMethodTotal {
    uint256 paymentMethodId;
    uint256 total;
}

enum IssueType { InvalidPlace, PlayerNotAllowed, StickerNotAllowed, ObjectiveNotAllowed, InsufficientFunds, InsufficientAllowance}

struct SlapIssue {
    IssueType issueCode;
    uint256 recordId;
    uint256 value;
}

struct StoredPlace {
    uint256 slapCount;
    mapping (uint256 => uint256) slaps;
}

contract StickerChain is Ownable, ERC721A {
    event StickerSlapped(uint256 indexed placeId, uint256 indexed stickerId, address indexed player, uint256 slapId, uint64 size);

    error InsufficientFunds(uint256 paymentMethodId);
    error InvalidPlaceId(uint256 placeId);
    error PlayerIsBanned();
    error SlapNotAllowed(uint256 stickerId);
    error InvalidStart();
    error NoValidSlap();

    StickerDesigns immutable public stickerDesignsContract;
    IPaymentMethod immutable public paymentMethodContract;

    uint256 public slapFee;
    uint256 public slapFeeForSize(uint _size) view returns (uint) {
        return slapFee * _size * _size * _size;
    }

    mapping (uint256 => StoredSlap) private _slaps;
    mapping (uint256 => StoredPlace) private _board;
    mapping (uint256 => uint256) private _stickerDesignSlapCounts;

    mapping (address => bool) private _bannedPlayers;

    constructor(uint _initialSlapFee, address payable _stickerDesignsAddress, address payable _paymentMethodAddress)
        Ownable(msg.sender) ERC721A("StickerChain", "SLAP")  {
        slapFee = _initialSlapFee;
        stickerDesignsContract = StickerDesigns(_stickerDesignsAddress);
        paymentMethodContract = IPaymentMethod(_paymentMethodAddress);
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

    function _readSlap(uint256 _slapId) internal view returns (Slap memory result) {
        StoredSlap memory storedSlap = _slaps[_slapId];
        if (stickerDesignsContract.isBannedStickerDesign(storedSlap.stickerId)) {
            return result;
        }
        result = Slap({
            slapId: _slapId,
            stickerId: storedSlap.stickerId,
            placeId: storedSlap.placeId,
            height: storedSlap.height,
            slappedAt: storedSlap.slappedAt,
            size: storedSlap.size,
            player: storedSlap.player
        });
    }

    function getSlap(uint _slapId) external view returns (Slap memory) {
        return _readSlap(_slapId);
    }

    function getSlaps(uint[] calldata _slapIds) external view returns (Slap[] memory) {
        Slap[] memory slaps = new Slap[](_slapIds.length);
        for (uint i = 0; i < _slapIds.length; i++) {
            slaps[i] = _readSlap(_slapIds[i]);
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
            uint256 _slapId = _board[_placeId].slaps[i];
            slaps[resultIndex] = _readSlap(_slapId);
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

    function costOfSlaps(address _player, NewSlap[] calldata _newSlaps)
    external view
    returns (PaymentMethodTotal[] memory costs)
    {
        uint _newSlapCount = _newSlaps.length;
        if (_newSlapCount == 1) {
            if (_newSlaps[0].paymentMethodId == 0) {
                costs = new PaymentMethodTotal[](1);
                costs[0].total = slapFeeForSize(_newSlaps[0].size) + _newSlaps[0].slapFee;
            }else{
                costs = new PaymentMethodTotal[](2);
                costs[0].total = slapFeeForSize(_newSlaps[0].size);
                costs[1].paymentMethodId = _newSlaps[0].paymentMethodId;
                costs[1].total = _newSlaps[0].slapFee;
            }
            return costs;
        }
        // multiple slaps, up to (slap count) payment methods
        uint paymentMethodArraySize = _newSlapCount;
        paymentMethodTotals = new PaymentMethodTotal[](paymentMethodArraySize);
        uint paymentMethodCount = 1;
        for (uint i = 0; i < _newSlapCount; i++) {
            paymentMethodTotals[0].total += slapFeeForSize(_newSlaps[i].size);
            if (_newSlaps[i].paymentMethodId != 0) {
                bool found = false;
                for (uint j = 1; j < paymentMethodCount; j++) {
                    if (paymentMethodTotals[j].paymentMethodId == _newSlaps[i].paymentMethodId) {
                        paymentMethodTotals[j].total += _newSlaps[i].slapFee;
                        found = true;
                        break;
                    }
                }
                if (!found && paymentMethodCount < paymentMethodArraySize) {
                    paymentMethodTotals[paymentMethodCount].paymentMethodId = _newSlaps[i].paymentMethodId;
                    paymentMethodTotals[paymentMethodCount].total = _newSlaps[i].slapFee;
                    paymentMethodCount++;
                }
            }
        }
        return paymentMethodTotals;
    }

    function checkSlaps(address _player, NewSlap[] calldata _newSlaps)
    external view
    returns (SlapIssue[] memory issues)
    {
        uint slapCount = _newSlaps.length;
        uint issueCount;
        if (_bannedPlayers[_player]) {
            issues[issueCount] = SlapIssue({issueCode: IssueType.PlayerNotAllowed, recordId: 0, value: 0});
            issueCount++;
        }
        PaymentMethodTotal[] memory costs = costOfSlaps(_player, _newSlaps);
        uint paymentMethodCount = costs.length;
        for (uint i = 0; i < paymentMethodCount; i++) {
            if (i == 0) {
                uint playerEthBalance = address(_player).balance;
                if (costs[0].total > playerEthBalance) {
                    uint neededEth = costs[0].total - playerEthBalance;
                    issues[issueCount] = SlapIssue({issueCode: IssueType.InsufficientFunds, recordId: 0, value: neededEth});
                    issueCount++;
                }
                continue;
            }
            (uint balanceNeeded, uint allowanceNeeded) = paymentMethodContract.addressCanPay(costs[i].paymentMethodId, _player, address(this), costs[i].total);
            if (balanceNeeded > 0) {
                issues[issueCount] = SlapIssue({issueCode: IssueType.InsufficientFunds, recordId: costs[i].paymentMethodId, value: balanceNeeded});
                issueCount++;
            }
            if (allowanceNeeded > 0) {
                issues[issueCount] = SlapIssue({issueCode: IssueType.InsufficientAllowance, recordId: costs[i].paymentMethodId, value: allowanceNeeded});
                issueCount++;
            }
        }
        for (uint i = 0; i < slapCount; i++) {
            uint playerSlapCheckCode = stickerDesignsContract.accountCanSlapSticker(_player, _newSlaps[i].stickerId, _stickerDesignSlapCounts[_newSlaps[i].stickerId]);
            if (playerSlapCheckCode != 0) {
                issues[issueCount] = SlapIssue({issueCode: IssueType.StickerNotAllowed, recordId:  _newSlaps[i].stickerId, value: playerSlapCheckCode});
                issueCount++;
            }
            (bool placeIsValid, , , ,) = BlockPlaces.blockPlaceFromPlaceId(_newSlaps[i].placeId);
            if (!placeIsValid) {
                issues[issueCount] = SlapIssue({issueCode: IssueType.InvalidPlace, recordId: _newSlaps[i].placeId, value: 0});
                issueCount++;
            }
        }
    }

    function slap(NewSlap[] calldata _newSlaps)
    external payable
    returns (uint256[] memory slapIds)
    {
        if (_bannedPlayers[msg.sender]) {
            revert PlayerIsBanned();
        }
        uint slapCount = _newSlaps.length;
        slapIds = new uint256[](slapCount);
        for (uint i = 0; i < _newSlaps.length; i++) {
            if (!stickerDesignsContract.accountCanSlapSticker(msg.sender, _newSlaps[i].stickerId, _stickerDesignSlapCounts[_newSlaps[i].stickerId])) {
                revert SlapNotAllowed(_newSlaps[i].stickerId);
            }
            ethTotal += slapFeeForSize(_newSlaps[i].size);
            if (_newSlaps[i].paymentMethodId == 0) {
                ethTotal += _newSlaps[i].slapFee;
            }else{
                if (!paymentMethodContract.chargeAddressForPayment(_newSlaps[i].paymentMethodId, msg.sender, address(this), _newSlaps[i].slapFee)) {
                    revert InsufficientFunds(_newSlaps[i].paymentMethodId);
                }
            }
            slapIds[i] = _executeSlap(_newSlaps[i].placeId, _newSlaps[i].stickerId, _newSlaps[i].size);
        }
        if (msg.value < ethTotal) {
            revert InsufficientFunds(0);
        }
        return slapIds;
    }

    function _executeSlap(uint _placeId, uint _stickerId, uint64 size) internal returns (uint) {
        // validate slap inputs
        (bool isValid, , , ,) = BlockPlaces.blockPlaceFromPlaceId(_placeId);
        if (!isValid) {
            revert InvalidPlaceId(_placeId);
        }

        // mint slap token
        uint _slappedTokenId = _nextTokenId();
        _mint(msg.sender, 1);

        // track sticker design slap count
        _stickerDesignSlapCounts[_stickerId] += 1;

        // store slap data
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
        return _slappedTokenId;
    }


    // admin methods
    function setSlapFee(uint _newSlapFee) external onlyOwner {
        slapFee = _newSlapFee;
    }

    function banPlayers(address[] calldata _players, bool undoBan) external onlyOwner {
        for (uint i = 0; i < _players.length; i++) {
            _bannedPlayers[_players[i]] = !undoBan;
        }
    }

}