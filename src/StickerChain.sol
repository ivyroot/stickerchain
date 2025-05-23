// SPDX-License-Identifier: MIT
//
//   _____   _    _         _                    ___    _             _
//  (_____) (_)_ (_)       (_) _   ____  _     _(___)_ (_)           (_) _
// (_)___   (___) _    ___ (_)(_) (____)(_)__ (_)   (_)(_)__    ____  _ (_)__
//   (___)_ (_)  (_) _(___)(___) (_)_(_)(____)(_)    _ (____)  (____)(_)(____)
//   ____(_)(_)_ (_)(_)___ (_)(_)(__)__ (_)   (_)___(_)(_) (_)( )_( )(_)(_) (_)
//  (_____)  (__)(_) (____)(_) (_)(____)(_)     (___)  (_) (_) (__)_)(_)(_) (_)
//
//  StickerChain is a geocrypto map of the world
//
//  follow ivyroot for updates:
//
//        x.com/ivyroot_zk
//
//        farcaster.xyz/ivyroot
//
//
pragma solidity ^0.8.26;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuardTransient} from "openzeppelin-contracts/contracts/utils/ReentrancyGuardTransient.sol";
import "erc721a/contracts/ERC721A.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPaymentMethod} from "./IPaymentMethod.sol";
import {IPayoutMethod} from "./IPayoutMethod.sol";
import {StickerDesign, StickerDesigns, ERC20_PAYMENT_FAILED} from "./StickerDesigns.sol";
import {StickerObjectives} from "./StickerObjectives.sol";
import {IMetadataRenderer} from "./renderers/IMetadataRenderer.sol";
import "./IStickerObjective.sol";
import "block-places/BlockPlaces.sol";
import "forge-std/console.sol";

struct Place {
    uint256 placeId;
    uint256 lng;
    uint256 lngDecimal;
    uint256 lat;
    uint256 latDecimal;
    uint256 stickerId;
    uint256 slapId;
    uint256 slapCount;
}

struct Slap {
    uint256 slapId;
    uint256 stickerId;
    uint256 placeId;
    uint256 height;
    uint256 slappedAt;
    uint64 size;
    address player;
    uint256[] objectiveIds;
}

struct StoredSlap {
    uint256 placeId;
    uint256 height;
    uint256 stickerId;
    uint256 slappedAt;
    address slappedBy;
    uint64 size;
}

struct NewSlap {
    uint256 placeId;
    uint256 stickerId;
    uint64 size;
}

struct PaymentMethodTotal {
    uint256 paymentMethodId;
    uint256 total;
}

uint8 constant MAX_OBJECTIVES_PER_SLAP = 10;

enum IssueType { InvalidPlace, PlayerNotAllowed, StickerNotAllowed, ObjectiveNotAllowed, InsufficientFunds, InsufficientAllowance, TooManyObjectives}

struct SlapIssue {
    IssueType issueCode;
    uint256 recordId;
    uint256 value;
}

struct StoredPlace {
    uint256 slapCount;
    mapping (uint256 => uint256) slaps;
}

contract StickerChain is Ownable, ERC721A, ReentrancyGuardTransient {
    event StickerSlapped(uint256 indexed placeId, uint256 indexed stickerId, address indexed player, uint256 slapId, uint64 size);
    event SlapInObjective(uint256 indexed objectiveId, uint256 indexed slapId);
    event SlapFeeChanged(uint256 newFee);
    event PlayerReputationFeeChanged(uint256 newFee);
    event PlayerBanned(address indexed player);
    event PlayerUnbanned(address indexed player);

    error InsufficientFunds(uint256 paymentMethodId);
    error InvalidPlaceId(uint256 placeId);
    error TooManyObjectives();
    error PlayerIsBanned();
    error FeatureIsLocked();
    error InvalidAddress();
    error PermissionDenied();
    error InvalidStart();

    IPaymentMethod public paymentMethodContract;
    bool public paymentMethodContractIsLocked;

    StickerDesigns public stickerDesignsContract;
    bool public stickerDesignsContractIsLocked;

    IPayoutMethod public publisherPayoutMethod;
    bool public publisherPayoutMethodIsLocked;

    StickerObjectives public stickerObjectivesContract;
    bool public stickerObjectivesContractIsLocked;

    IPayoutMethod public objectivePayoutMethod;
    bool public objectivePayoutMethodIsLocked;

    IMetadataRenderer public metadataRenderer;
    bool public metadataRendererIsLocked;

    uint256 public slapFee;
    uint256 public playerReputationFee;

    mapping (uint256 => StoredSlap) private _slaps;
    mapping (uint256 => uint256[]) private _slapObjectives;
    mapping (uint256 => StoredPlace) private _board;
    mapping (uint256 => uint256) private _stickerDesignSlapCounts;

    mapping (address => bool) public initiatedPlayers;
    mapping (address => bool) public isBanned;

    address public operator;

    constructor(address _initialAdmin, uint _initialSlapFee, address payable _stickerDesignsAddress, address payable _paymentMethodAddress)
        Ownable(_initialAdmin) ERC721A("StickerChain", "SLAP")  {
        slapFee = _initialSlapFee;
        stickerDesignsContract = StickerDesigns(_stickerDesignsAddress);
        paymentMethodContract = IPaymentMethod(_paymentMethodAddress);
        operator = _initialAdmin;
    }

    function slapFeeForSize(uint _size) public view returns (uint) {
        return slapFee * _size * _size * _size;
    }

    function getPlace(uint _placeId) external view returns (Place memory) {
        (bool isValid, uint lng, uint lngDecimal, uint lat, uint latDecimal) = BlockPlaces.blockPlaceFromPlaceId(_placeId);
        if (!isValid) {
            revert InvalidPlaceId(_placeId);
        }
        uint slapId;
        uint stickerId;
        uint slapCount = _board[_placeId].slapCount;
        if (slapCount > 0) {
            slapId = _board[_placeId].slaps[slapCount];
            // skip over any slaps that have been burned
            while (slapId > 0 && _slaps[slapId].placeId == 0) {
                slapCount--;
                if (slapCount == 0) {
                    slapId = 0;
                } else {
                    slapId = _board[_placeId].slaps[slapCount];
                }
            }
            if (slapId > 0) {
                stickerId = getSlapStickerId(slapId);
            }
        }
        Place memory place = Place({
            placeId: _placeId,
            lng: lng,
            lngDecimal: lngDecimal,
            lat: lat,
            latDecimal: latDecimal,
            slapId: slapId,
            stickerId: stickerId,
            slapCount: slapCount
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
        if (stickerDesignsContract.isBannedStickerDesign(storedSlap.stickerId) ||
            isBanned[storedSlap.slappedBy] ||
            !_exists(_slapId)) {
            return result;
        }
        result = Slap({
            slapId: _slapId,
            stickerId: storedSlap.stickerId,
            placeId: storedSlap.placeId,
            height: storedSlap.height,
            slappedAt: storedSlap.slappedAt,
            size: storedSlap.size,
            player: storedSlap.slappedBy,
            objectiveIds: _slapObjectives[_slapId]
        });
    }

    function getSlap(uint _slapId) external view returns (Slap memory) {
        return _readSlap(_slapId);
    }

    function getSlapStickerId(uint _slapId) public view returns (uint) {
        uint _stickerId = _slaps[_slapId].stickerId;
        if (stickerDesignsContract.isBannedStickerDesign(_stickerId)) {
            return 0;
        }
        return _stickerId;
    }

    function getSlaps(uint[] calldata _slapIds) external view returns (Slap[] memory) {
        Slap[] memory slaps = new Slap[](_slapIds.length);
        for (uint i = 0; i < _slapIds.length; i++) {
            slaps[i] = _readSlap(_slapIds[i]);
        }
        return slaps;
    }

    function getSlaps(uint _start, uint _count) external view returns (Slap[] memory) {
        uint256 nextTokenId = _nextTokenId();
        if (_start >= nextTokenId) {
            revert InvalidStart();
        }
        uint256 end = _start + _count;
        if (end > nextTokenId) {
            end = nextTokenId;
        }
        uint256 length = end - _start;
        Slap[] memory slaps = new Slap[](length);
        uint resultIndex = 0;
        for (uint i = _start; i < end; i++) {
            slaps[resultIndex] = _readSlap(i);
            resultIndex++;
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

    function costOfSlaps(address _player, NewSlap[] calldata _newSlaps, uint256[] calldata _objectives)
    public view
    returns (PaymentMethodTotal[] memory)
    {
        if (isBanned[_player]) {
            revert PlayerIsBanned();
        }
        uint _newSlapCount = _newSlaps.length;
        uint _objectiveCount = _objectives.length;
        // each slap and objective could have a different payment method
        uint paymentMethodArraySize = _newSlapCount + _objectiveCount;
        PaymentMethodTotal[] memory costs = new PaymentMethodTotal[](paymentMethodArraySize);
        uint paymentMethodCount = 1;
        // check for player reputation fee
        if (!initiatedPlayers[_player]) {
            costs[0].total += playerReputationFee;
        }
        // check costs of sticker designs for passed in slaps
        for (uint i = 0; i < _newSlapCount; i++) {
            costs[0].total += slapFeeForSize(_newSlaps[i].size);
            (uint paymentMethodId, uint64 price,) = stickerDesignsContract.getStickerDesignPrice(_newSlaps[i].stickerId);
            if (paymentMethodId == 0) {
                costs[0].total += price;
            } else {
                bool found = false;
                for (uint j = 1; j < paymentMethodCount; j++) {
                    if (costs[j].paymentMethodId == paymentMethodId) {
                        costs[j].total += price;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    costs[paymentMethodCount].paymentMethodId = paymentMethodId;
                    costs[paymentMethodCount].total = price;
                    paymentMethodCount++;
                }
            }
        }
        // check costs of objectives for passed in slaps
        FreshSlap[] memory _priceCheckSlaps = new FreshSlap[](_newSlapCount);
       for (uint i = 0; i < _newSlapCount; i++) {
            _priceCheckSlaps[i] = FreshSlap({
                slapId: 0,
                placeId: _newSlaps[i].placeId,
                stickerId: _newSlaps[i].stickerId,
                size: _newSlaps[i].size
            });
        }
        for (uint i = 0; i < _objectiveCount; i++) {
            IStickerObjective obj = stickerObjectivesContract.getObjective(_objectives[i]);
            if (address(obj) == address(0)) {
                continue;
            }
            (address objPaymentCoin, uint objCost,) = obj.costOfSlaps(_player, _priceCheckSlaps);
            if (objPaymentCoin == address(0)) {
                costs[0].total += objCost;
            } else {
                uint objPaymentMethodId = paymentMethodContract.getIdOfPaymentMethod(objPaymentCoin);
                if (objPaymentMethodId == 0) {
                    continue; // invalid payment method
                }
                bool found = false;
                for (uint j = 1; j < paymentMethodCount; j++) {
                    if (costs[j].paymentMethodId == objPaymentMethodId) {
                        costs[j].total += objCost;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    costs[paymentMethodCount].paymentMethodId = paymentMethodContract.getIdOfPaymentMethod(objPaymentCoin);
                    costs[paymentMethodCount].total = objCost;
                    paymentMethodCount++;
                }
            }
        }
        // make new array with only the payment methods that have a cost
        PaymentMethodTotal[] memory finalCosts = new PaymentMethodTotal[](paymentMethodCount);
        uint finalCostsIndex;
        for (uint i = 0; i < paymentMethodCount; i++) {
            if (costs[i].total > 0) {
                finalCosts[finalCostsIndex].total = costs[i].total;
                finalCosts[finalCostsIndex].paymentMethodId = costs[i].paymentMethodId;
                finalCostsIndex++;
            }
        }
        return finalCosts;
    }

    function checkSlaps(address _player, NewSlap[] calldata _newSlaps, uint256[] calldata _objectives)
    public view
    returns (SlapIssue[] memory)
    {
        if (isBanned[_player]) {
            SlapIssue[] memory banIssue = new SlapIssue[](1);
            banIssue[0] = SlapIssue({issueCode: IssueType.PlayerNotAllowed, recordId: 0, value: 0});
            return banIssue;
        }

        uint slapCount = _newSlaps.length;
        uint maxIssueCount = slapCount * 2 + 4; // Maximum possible issues: 2 per slap + 3 for player status and funds + 1 for too many objectives
        SlapIssue[] memory issues = new SlapIssue[](maxIssueCount);
        uint issueCount;

        PaymentMethodTotal[] memory costs = costOfSlaps(_player, _newSlaps, _objectives);
        uint paymentMethodCount = costs.length;

        if (!initiatedPlayers[_player]) {
            costs[0].total += playerReputationFee;
        }

        for (uint i = 0; i < paymentMethodCount; i++) {
            if (i == 0) {
                uint playerEthBalance = address(_player).balance;
                if (costs[0].total > playerEthBalance) {
                    uint neededEth = costs[0].total - playerEthBalance;
                    issues[issueCount++] = SlapIssue({issueCode: IssueType.InsufficientFunds, recordId: 0, value: neededEth});
                }
                continue;
            }
            (uint balanceNeeded, uint allowanceNeeded) = paymentMethodContract.addressCanPay(costs[i].paymentMethodId, _player, costs[i].total);
            if (balanceNeeded > 0) {
                issues[issueCount++] = SlapIssue({issueCode: IssueType.InsufficientFunds, recordId: costs[i].paymentMethodId, value: balanceNeeded});
            }
            if (allowanceNeeded > 0) {
                issues[issueCount++] = SlapIssue({issueCode: IssueType.InsufficientAllowance, recordId: costs[i].paymentMethodId, value: allowanceNeeded});
            }
        }

        for (uint i = 0; i < slapCount; i++) {
            uint playerSlapCheckCode = stickerDesignsContract.accountCanSlapSticker(_player, _newSlaps[i].stickerId, _stickerDesignSlapCounts[_newSlaps[i].stickerId]);
            if (playerSlapCheckCode != 0) {
                issues[issueCount++] = SlapIssue({issueCode: IssueType.StickerNotAllowed, recordId:  _newSlaps[i].stickerId, value: playerSlapCheckCode});
            }
            (bool placeIsValid, , , ,) = BlockPlaces.blockPlaceFromPlaceId(_newSlaps[i].placeId);
            if (!placeIsValid) {
                issues[issueCount++] = SlapIssue({issueCode: IssueType.InvalidPlace, recordId: _newSlaps[i].placeId, value: 0});
            }
        }
        if (_objectives.length > MAX_OBJECTIVES_PER_SLAP) {
            issues[issueCount++] = SlapIssue({issueCode: IssueType.TooManyObjectives, recordId: 0, value: 0});
        }

        // Create a new array with the exact number of issues found
        SlapIssue[] memory finalIssues = new SlapIssue[](issueCount);
        for (uint i = 0; i < issueCount; i++) {
            finalIssues[i] = issues[i];
        }

        return finalIssues;
    }

    function slap(NewSlap[] calldata _newSlaps, uint256[] calldata _objectives)
    external payable nonReentrant
    returns (uint256[] memory slapIds, uint256[] memory slapStatuses)
    {
        if (isBanned[msg.sender]) {
            revert PlayerIsBanned();
        }
        uint slapCount = _newSlaps.length;
        uint totalBill;
        uint slapSuccessCount;
        uint stickerPaymentMethodId;
        uint64 stickerPrice;
        uint stickerBaseTokenPrice;
        address stickerFeeRecipient;
        slapIds = new uint256[](slapCount);
        slapStatuses = new uint256[](slapCount);
        uint slapIssue;
        bool chargeSuccess;
        IERC20 _chargedCoin;
        for (uint i = 0; i < _newSlaps.length; i++) {
            slapIssue = stickerDesignsContract.accountCanSlapSticker(msg.sender, _newSlaps[i].stickerId, _stickerDesignSlapCounts[_newSlaps[i].stickerId]);
            if (slapIssue != 0) {
                slapStatuses[i] = slapIssue;
                continue;
            }
            stickerBaseTokenPrice = 0;
            _chargedCoin = IERC20(address(0));
            (stickerPaymentMethodId, stickerPrice, stickerFeeRecipient) = stickerDesignsContract.getStickerDesignPrice(_newSlaps[i].stickerId);
            if (stickerPrice > 0)  {
                if (stickerPaymentMethodId == 0) {
                    totalBill += stickerPrice;
                    stickerBaseTokenPrice = stickerPrice;
                }else {
                    _chargedCoin = paymentMethodContract.getPaymentMethod(stickerPaymentMethodId);
                    if (address(_chargedCoin) == address(0)) {
                        slapStatuses[i] = ERC20_PAYMENT_FAILED;
                        continue;
                    }
                    chargeSuccess = _chargedCoin.transferFrom(msg.sender, address(publisherPayoutMethod), stickerPrice);
                    if (!chargeSuccess) {
                        slapStatuses[i] = ERC20_PAYMENT_FAILED;
                        continue;
                    }
                }
                publisherPayoutMethod.deposit{value: stickerBaseTokenPrice}(address(_chargedCoin), stickerPrice, stickerFeeRecipient, false);
            }
            uint protocolFee = slapFeeForSize(_newSlaps[i].size);
            publisherPayoutMethod.deposit{value: protocolFee}(address(0), protocolFee, stickerFeeRecipient, true);
            totalBill += protocolFee;
            slapSuccessCount++;
            slapIds[i] = _executeSlap(_newSlaps[i].placeId, _newSlaps[i].stickerId, _newSlaps[i].size);
        }
        // call any provided objectives
        if (_objectives.length > 0 && slapSuccessCount > 0) {
            if (_objectives.length > MAX_OBJECTIVES_PER_SLAP) {
                revert TooManyObjectives();
            }
            // make a list of only slaps that succeeded
            FreshSlap[] memory freshSlaps = new FreshSlap[](slapSuccessCount);
            uint currSlapIndex;
            for (uint i = 0; i < slapCount; i++) {
                if (slapStatuses[i] == 0) {
                    freshSlaps[currSlapIndex] = FreshSlap({
                        slapId: slapIds[i],
                        placeId: _newSlaps[i].placeId,
                        stickerId: _newSlaps[i].stickerId,
                        size: _newSlaps[i].size
                    });
                    currSlapIndex++;
                }
            }
            // pass the list of slaps to each objective
            for (uint i = 0; i < _objectives.length; i++) {
                IStickerObjective obj = stickerObjectivesContract.getObjective(_objectives[i]);
                if (address(obj) == address(0)) {
                    continue;
                }
                uint objectiveBaseTokenPrice = 0;
                (address objPaymentCoin, uint objCost, address objRecipient) = obj.costOfSlaps(msg.sender, freshSlaps);
                if (objPaymentCoin == address(0)) {
                    totalBill += objCost;
                    objectiveBaseTokenPrice = objCost;
                } else {
                    uint objPaymentMethodId = paymentMethodContract.getIdOfPaymentMethod(objPaymentCoin);
                    if (objPaymentMethodId == 0) {
                        continue; // skip to next objective
                    }
                    IERC20 _objCoin = IERC20(objPaymentCoin);
                    chargeSuccess = _objCoin.transferFrom(msg.sender, address(objectivePayoutMethod), objCost);
                    if (!chargeSuccess) {
                        continue; // skip to next objective
                    }
                }
                objectivePayoutMethod.deposit{value: objectiveBaseTokenPrice}(objPaymentCoin, objCost, objRecipient, false);
                uint[] memory includedSlapIds = obj.slapInObjective(msg.sender, freshSlaps);
                _writeObjectiveToSlaps(includedSlapIds, _objectives[i]);
            }
        }
        if (!initiatedPlayers[msg.sender]) {
            totalBill += playerReputationFee;
            initiatedPlayers[msg.sender] = true;
        }
        if (msg.value < totalBill) {
            revert InsufficientFunds(totalBill);
        }
        if (msg.value > totalBill) {
            payable(msg.sender).transfer(msg.value - totalBill);
        }
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
            slappedBy: msg.sender,
            size: size
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
        return _slappedTokenId;
    }

    function _writeObjectiveToSlaps(uint256[] memory _slapIds, uint256 _objectiveId) internal {
        for (uint i = 0; i < _slapIds.length; i++) {
            _slapObjectives[_slapIds[i]].push(_objectiveId);
            emit SlapInObjective(_objectiveId, _slapIds[i]);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return metadataRenderer.tokenURI(tokenId);
    }


    function burn(uint[] calldata _slapIds) external {
        for (uint i = 0; i < _slapIds.length; i++) {
            _burn(_slapIds[i], true);
        }
    }

    // set burned slaps to placeId 0
    function _afterTokenTransfers(
        address,
        address to,
        uint256 slapId,
        uint256
    ) internal override {
        if (to == address(0)) {
            _slaps[slapId].placeId = 0;
        }
    }


    // operator methods

    modifier onlyOperator() {
        if (msg.sender != operator) {
            revert PermissionDenied();
        }
        _;
    }

    function setSlapFee(uint _newSlapFee) external onlyOperator {
        slapFee = _newSlapFee;
        emit SlapFeeChanged(_newSlapFee);
    }

    function setPlayerReputationFee(uint _newPlayerReputationFee) external onlyOperator {
        playerReputationFee = _newPlayerReputationFee;
        emit PlayerReputationFeeChanged(_newPlayerReputationFee);
    }

    function banPlayers(address[] calldata _players, bool undoBan) external onlyOperator {
        for (uint i = 0; i < _players.length; i++) {
            isBanned[_players[i]] = !undoBan;
            if (!undoBan) {
                emit PlayerBanned(_players[i]);
            } else {
                emit PlayerUnbanned(_players[i]);
            }
        }
    }

    // admin methods
    function setOperator(address _newOperator) external onlyOwner {
        if (_newOperator == address(0)) {
            revert InvalidAddress();
        }
        operator = _newOperator;
    }

    // change the PaymentMethod contract address
    function setPaymentMethodContract(address payable _newPaymentMethodAddress) external onlyOwner {
        if (paymentMethodContractIsLocked) {
            revert FeatureIsLocked();
        }
        if (_newPaymentMethodAddress == address(0)) {
            revert InvalidAddress();
        }
        paymentMethodContract = IPaymentMethod(_newPaymentMethodAddress);
    }

    function lockPaymentMethodContract() external onlyOwner {
        paymentMethodContractIsLocked = true;
    }

    // change the StickerDesigns contract address
    function setStickerDesignsContract(address payable _newStickerDesignsAddress) external onlyOwner {
        if (stickerDesignsContractIsLocked) {
            revert FeatureIsLocked();
        }
        if (_newStickerDesignsAddress == address(0)) {
            revert InvalidAddress();
        }
        stickerDesignsContract = StickerDesigns(_newStickerDesignsAddress);
    }
    function lockStickerDesignsContract() external onlyOwner {
        stickerDesignsContractIsLocked = true;
    }

    // change the StickerObjectives contract address
    function setStickerObjectivesContract(address payable _newStickerObjectivesAddress) external onlyOwner {
        if (stickerObjectivesContractIsLocked) {
            revert FeatureIsLocked();
        }
        if (_newStickerObjectivesAddress == address(0)) {
            revert InvalidAddress();
        }
        stickerObjectivesContract = StickerObjectives(_newStickerObjectivesAddress);
    }

    function lockStickerObjectivesContract() external onlyOwner {
        stickerObjectivesContractIsLocked = true;
    }

    // change the Publisher PayoutMethod contract address
    function setPublisherPayoutMethodContract(address payable _newPublisherPayoutMethodAddress) external onlyOwner {
        if (publisherPayoutMethodIsLocked) {
            revert FeatureIsLocked();
        }
        if (_newPublisherPayoutMethodAddress == address(0)) {
            revert InvalidAddress();
        }
        publisherPayoutMethod = IPayoutMethod(_newPublisherPayoutMethodAddress);
    }

    function lockPublisherPayoutMethodContract() external onlyOwner {
        publisherPayoutMethodIsLocked = true;
    }

    // change the Objective PayoutMethod contract address
    function setObjectivePayoutMethodContract(address payable _newObjectivePayoutMethodAddress) external onlyOwner {
        if (objectivePayoutMethodIsLocked) {
            revert FeatureIsLocked();
        }
        if (_newObjectivePayoutMethodAddress == address(0)) {
            revert InvalidAddress();
        }
        objectivePayoutMethod = IPayoutMethod(_newObjectivePayoutMethodAddress);
    }

    function lockObjectivePayoutMethodContract() external onlyOwner {
        objectivePayoutMethodIsLocked = true;
    }

    // change the MetadataRenderer contract address
    function setMetadataRendererContract(address _newMetadataRendererAddress) external onlyOwner {
        if (metadataRendererIsLocked) {
            revert FeatureIsLocked();
        }
        if (_newMetadataRendererAddress == address(0)) {
            revert InvalidAddress();
        }
        metadataRenderer = IMetadataRenderer(_newMetadataRendererAddress);
    }

    function lockMetadataRendererContract() external onlyOwner {
        metadataRendererIsLocked = true;
    }

}

