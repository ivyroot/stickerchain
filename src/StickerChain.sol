// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuardTransient} from "openzeppelin-contracts/contracts/utils/ReentrancyGuardTransient.sol";
import "erc721a/contracts/ERC721A.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPaymentMethod} from "./IPaymentMethod.sol";
import {IPayoutMethod} from "./IPayoutMethod.sol";
import {StickerDesign, StickerDesigns, ERC20_PAYMENT_FAILED} from "./StickerDesigns.sol";
import {StickerObjectives} from "./StickerObjectives.sol";
import {FreshSlap, IStickerObjective} from "./IStickerObjective.sol";
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

contract StickerChain is Ownable, ERC721A, ReentrancyGuardTransient {
    event StickerSlapped(uint256 indexed placeId, uint256 indexed stickerId, address indexed player, uint256 slapId, uint64 size);

    error InsufficientFunds(uint256 paymentMethodId);
    error InvalidPlaceId(uint256 placeId);
    error PlayerIsBanned();
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

    uint256 public slapFee;

    mapping (uint256 => StoredSlap) private _slaps;
    mapping (uint256 => StoredPlace) private _board;
    mapping (uint256 => uint256) private _stickerDesignSlapCounts;

    mapping (address => bool) private _bannedPlayers;

    constructor(address _initialAdmin, uint _initialSlapFee, address payable _stickerDesignsAddress, address payable _paymentMethodAddress)
        Ownable(_initialAdmin) ERC721A("StickerChain", "SLAP")  {
        slapFee = _initialSlapFee;
        stickerDesignsContract = StickerDesigns(_stickerDesignsAddress);
        paymentMethodContract = IPaymentMethod(_paymentMethodAddress);
    }

    function slapFeeForSize(uint _size) public view returns (uint) {
        return slapFee * _size * _size * _size;
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
            player: ownerOf(_slapId)
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

    function baseTokenCostOfSlaps(NewSlap[] calldata _newSlaps) public view returns (uint256) {
        uint256 totalCost;
        for (uint i = 0; i < _newSlaps.length; i++) {
            totalCost += slapFeeForSize(_newSlaps[i].size);
            (uint paymentMethodId, uint64 price,) = stickerDesignsContract.getStickerDesignPrice(_newSlaps[i].stickerId);
            if (paymentMethodId == 0) {
                totalCost += price;
            }
        }
        return totalCost;
    }

    function totalCostsOfSlaps(address _player, NewSlap[] calldata _newSlaps)
    public view
    returns (PaymentMethodTotal[] memory costs)
    {
        if (_bannedPlayers[_player]) {
            revert PlayerIsBanned();
        }
        uint _newSlapCount = _newSlaps.length;
        // multiple slaps, up to (slap count) payment methods
        uint paymentMethodArraySize = _newSlapCount;
        costs = new PaymentMethodTotal[](paymentMethodArraySize);
        uint paymentMethodCount = 1;
        for (uint i = 0; i < _newSlapCount; i++) {
            costs[0].total += slapFeeForSize(_newSlaps[i].size);
            (uint paymentMethodId, uint64 price,) = stickerDesignsContract.getStickerDesignPrice(_newSlaps[i].stickerId);
            if (paymentMethodId != 0) {
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
    }

    function checkSlaps(address _player, NewSlap[] calldata _newSlaps)
    public view
    returns (SlapIssue[] memory issues)
    {
        uint slapCount = _newSlaps.length;
        uint issueCount;
        if (_bannedPlayers[_player]) {
            issues[issueCount] = SlapIssue({issueCode: IssueType.PlayerNotAllowed, recordId: 0, value: 0});
            issueCount++;
        }
        PaymentMethodTotal[] memory costs = totalCostsOfSlaps(_player, _newSlaps);
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

    function slap(NewSlap[] calldata _newSlaps, uint256[] calldata _objectives)
    external payable nonReentrant
    returns (uint256[] memory slapIds, uint256[] memory slapStatuses)
    {
        if (_bannedPlayers[msg.sender]) {
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
            (stickerPaymentMethodId, stickerPrice, stickerFeeRecipient) = stickerDesignsContract.getStickerDesignPrice(_newSlaps[i].stickerId);
            if (stickerPrice > 0)  {
                if (stickerPaymentMethodId == 0) {
                    totalBill += stickerPrice;
                    stickerBaseTokenPrice = stickerPrice;
                }else{
                    (chargeSuccess, _chargedCoin) = paymentMethodContract.chargeAddressForPayment(stickerPaymentMethodId, msg.sender, address(publisherPayoutMethod), stickerPrice);
                    if (!chargeSuccess) {
                        slapStatuses[i] = ERC20_PAYMENT_FAILED;
                        continue;
                    }
                }
                console.log("about to deposit from ");
                console.log(address(this));
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
                }else{
                    uint objPaymentMethodId = paymentMethodContract.getIdOfPaymentMethod(objPaymentCoin);
                    if (objPaymentMethodId == 0) {
                        continue;
                    }
                    (chargeSuccess, _chargedCoin) = paymentMethodContract.chargeAddressForPayment(objPaymentMethodId, msg.sender, objRecipient, objCost);
                    if (!chargeSuccess) {
                        continue;
                    }
                }
                objectivePayoutMethod.deposit{value: objectiveBaseTokenPrice}(objPaymentCoin, objCost, objRecipient, false);
                obj.slapInObjective(msg.sender, freshSlaps);
            }
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


    // admin methods
    function setSlapFee(uint _newSlapFee) external onlyOwner {
        slapFee = _newSlapFee;
    }

    function banPlayers(address[] calldata _players, bool undoBan) external onlyOwner {
        for (uint i = 0; i < _players.length; i++) {
            _bannedPlayers[_players[i]] = !undoBan;
        }
    }

    // change the PaymentMethod contract address
    function setPaymentMethodContract(address payable _newPaymentMethodAddress) external onlyOwner {
        require(!paymentMethodContractIsLocked, 'StickerChain: PaymentMethod contract is locked');
        require(_newPaymentMethodAddress != address(0), 'StickerChain: PaymentMethod contract address cannot be 0');
        paymentMethodContract = IPaymentMethod(_newPaymentMethodAddress);
    }

    function lockPaymentMethodContract() external onlyOwner {
        paymentMethodContractIsLocked = true;
    }

    // change the StickerDesigns contract address
    function setStickerDesignsContract(address payable _newStickerDesignsAddress) external onlyOwner {
        require(!stickerDesignsContractIsLocked, 'StickerChain: StickerDesigns contract is locked');
        require(_newStickerDesignsAddress != address(0), 'StickerChain: StickerDesigns contract address cannot be 0');
        stickerDesignsContract = StickerDesigns(_newStickerDesignsAddress);
    }
    function lockStickerDesignsContract() external onlyOwner {
        stickerDesignsContractIsLocked = true;
    }

    // change the StickerObjectives contract address
    function setStickerObjectivesContract(address payable _newStickerObjectivesAddress) external onlyOwner {
        require(!stickerObjectivesContractIsLocked, 'StickerChain: StickerObjectives contract is locked');
        require(_newStickerObjectivesAddress != address(0), 'StickerChain: StickerObjectives contract address cannot be 0');
        stickerObjectivesContract = StickerObjectives(_newStickerObjectivesAddress);
    }

    function lockStickerObjectivesContract() external onlyOwner {
        stickerObjectivesContractIsLocked = true;
    }

    // change the Publisher PayoutMethod contract address
    function setPublisherPayoutMethodContract(address payable _newPublisherPayoutMethodAddress) external onlyOwner {
        require(!publisherPayoutMethodIsLocked, 'StickerChain: PublisherPayoutMethod contract is locked');
        require(_newPublisherPayoutMethodAddress != address(0), 'StickerChain: PublisherPayoutMethod contract address cannot be 0');
        publisherPayoutMethod = IPayoutMethod(_newPublisherPayoutMethodAddress);
    }

    function lockPublisherPayoutMethodContract() external onlyOwner {
        publisherPayoutMethodIsLocked = true;
    }

    // change the Objective PayoutMethod contract address
    function setObjectivePayoutMethodContract(address payable _newObjectivePayoutMethodAddress) external onlyOwner {
        require(!objectivePayoutMethodIsLocked, 'StickerChain: ObjectivePayoutMethod contract is locked');
        require(_newObjectivePayoutMethodAddress != address(0), 'StickerChain: ObjectivePayoutMethod contract address cannot be 0');
        objectivePayoutMethod = IPayoutMethod(_newObjectivePayoutMethodAddress);
    }

    function lockObjectivePayoutMethodContract() external onlyOwner {
        objectivePayoutMethodIsLocked = true;
    }

}