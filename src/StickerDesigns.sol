// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPaymentMethod} from "./IPaymentMethod.sol";

uint constant STICKER_CAPPED = 101;
uint constant STICKER_SOLD_OUT = 102;
uint constant PLAYER_NOT_ALLOWED = 103;
uint constant STICKER_NOT_FOUND = 404;
uint constant ERC20_PAYMENT_FAILED = 505;
uint constant GATE_BROKEN = 411;

struct NewStickerDesign {
    address payoutAddress;
    uint64 price;
    uint256 paymentMethodId; // 0 for ETH
    uint64 limitCount;
    uint64 limitTime;
    address limitToHolders;
    bytes metadataCID;
}

struct StickerDesign {
    address originalPublisher;
    address currentPublisher;
    address payoutAddress;
    uint64 publishedAt;
    uint64 price;
    uint256 paymentMethodId; // 0 for ETH
    uint64 limit;
    uint64 endTime;
    address limitToHolders;
    bytes metadataCID;
}

contract StickerDesigns is Ownable {
    // sticker events
    event StickerDesignPublished(uint256 indexed stickerId, address indexed publisher, address indexed payoutAddress, bytes metadataCID);
    event StickerPublisherChanged(uint256 indexed stickerId, address indexed from, address indexed to);
    event StickerPriceSet(uint256 indexed stickerId, uint256 indexed paymentMethodId, uint256 price);
    event StickerEndTimeChanged(uint256 indexed stickerId, uint256 endTime);
    event StickerCapped(uint256 indexed stickerId);
    // admin events
    event AdminFeeRecipientChanged(address newRecipient);
    event PublisherReputationFeeChanged(uint256 newFee);
    event StickerRegistrationFeeChanged(uint256 newFee);

    error PublisherPermissionsIssue();
    error InvalidPublishingFee(uint256 requiredFee);
    error InvalidEndTime();
    error CannotModifyEndTime();
    error InvalidAccount();
    error InvalidRecipient();
    error InvalidStickerDesignId(uint256 stickerId);
    error InvalidPaymentMethodId(uint256 paymentMethodId);

    IPaymentMethod public paymentMethodContract;
    address payable public adminFeeRecipient;
    uint256 public publisherReputationFee;
    uint256 public stickerRegistrationFee;
    uint256 public nextStickerDesignId = 1;

    mapping (address => bool) private goodStandingPublishers;
    mapping (address => bool) private bannedPublishers;
    mapping (uint256 => bool) private bannedStickerDesigns;
    mapping (uint256 => StickerDesign) private _stickerDesigns;

    constructor(IPaymentMethod _payments, address _initialAdmin, uint _reputationFee, uint _registrationFee) Ownable(_initialAdmin) {
        paymentMethodContract = _payments;
        _persistAdminFeeRecipient(_initialAdmin);
        publisherReputationFee = _reputationFee;
        stickerRegistrationFee = _registrationFee;
    }

    function costToPublish(address _publisher) external view returns (uint256) {
        if (bannedPublishers[_publisher]) {
            revert PublisherPermissionsIssue();
        }
        return goodStandingPublishers[_publisher] ? stickerRegistrationFee : publisherReputationFee + stickerRegistrationFee;
    }


    // View methods

    function accountCanSlapSticker(address _account, uint256 _stickerId, uint256 _currentSlaps) external view  returns (uint) {
        if (!_isValidStickerId(_stickerId)) {
            return STICKER_NOT_FOUND;
        }
        if (_isCappedStickerDesign(_stickerId)) {
            return STICKER_CAPPED;
        }
        if ((_stickerDesigns[_stickerId].limit > 0) &&
            (_currentSlaps >= _stickerDesigns[_stickerId].limit)) {
            return STICKER_SOLD_OUT;
        }
        address gate = _stickerDesigns[_stickerId].limitToHolders;
        if (gate != address(0)) {
            (bool success, bytes memory returnData) = gate.staticcall(
                abi.encodeWithSignature("balanceOf(address)", _account)
            );
            if (!success) {
                // gate contract tried to change state
                return GATE_BROKEN;
            }
            uint256 balance = abi.decode(returnData, (uint256));
            if (balance == 0) {
                return PLAYER_NOT_ALLOWED;
            }
        }
        return 0;
    }

    function getStickerDesign(uint256 _stickerId) external view returns (StickerDesign memory) {
        return _readStickerDesign(_stickerId);
    }

    function getStickerDesignPrice(uint256 _stickerId) external view returns (uint256 paymentMethodId, uint64 price) {
        if (_isValidStickerId(_stickerId)) {
            paymentMethodId = _stickerDesigns[_stickerId].paymentMethodId;
            price = _stickerDesigns[_stickerId].price;
        }
    }

    function getStickerDesigns(uint256[] calldata _stickerIds) external view returns (StickerDesign[] memory) {
        StickerDesign[] memory designs = new StickerDesign[](_stickerIds.length);
        for (uint256 i = 0; i < _stickerIds.length; i++) {
            designs[i] = _readStickerDesign(_stickerIds[i]);
        }
        return designs;
    }

    function _isValidStickerId(uint256 _stickerId) internal view returns (bool) {
        return _stickerId > 0 && _stickerId < nextStickerDesignId && !bannedStickerDesigns[_stickerId];
    }

    function _readStickerDesign(uint256 _stickerId) internal view returns (StickerDesign memory result) {
        if (_isValidStickerId(_stickerId)) {
            result = _stickerDesigns[_stickerId];
        }
    }

    function isPublisherInGoodStanding(address _publisher) external view returns (bool) {
        return _checkGoodStandingPublisher(_publisher);
    }

    function isBannedPublisher(address _publisher) external view returns (bool) {
        return bannedPublishers[_publisher];
    }

    function isBannedStickerDesign(uint256 _stickerId) external view returns (bool) {
        return bannedStickerDesigns[_stickerId];
    }

    function isCappedStickerDesign(uint256 _stickerId) external view returns (bool) {
        return _isCappedStickerDesign(_stickerId);
    }


    // Publisher methods

    function publishStickerDesign(NewStickerDesign calldata newDesign) external payable returns(uint256) {
        if (bannedPublishers[msg.sender]) {
            revert PublisherPermissionsIssue();
        }
        bool firstSticker = !goodStandingPublishers[msg.sender];
        uint256 requiredFee = firstSticker ? publisherReputationFee + stickerRegistrationFee : stickerRegistrationFee;
        if (msg.value != requiredFee) {
            revert InvalidPublishingFee(requiredFee);
        }
        uint256 newStickerId = nextStickerDesignId;
        uint64 endTime;
        if (newDesign.limitTime > 0) {
            endTime = uint64(block.timestamp > newDesign.limitTime ? block.timestamp : newDesign.limitTime);
        }
        _stickerDesigns[newStickerId] = StickerDesign({
            originalPublisher: msg.sender,
            currentPublisher: msg.sender,
            payoutAddress: newDesign.payoutAddress,
            publishedAt: uint64(block.timestamp),
            price: newDesign.price,
            paymentMethodId: newDesign.paymentMethodId,
            limit: newDesign.limitCount,
            limitToHolders: newDesign.limitToHolders,
            endTime: endTime,
            metadataCID: newDesign.metadataCID
        });
        if (firstSticker) {
            goodStandingPublishers[msg.sender] = true;
        }
        nextStickerDesignId++;
        adminFeeRecipient.transfer(msg.value);
        emit StickerDesignPublished(newStickerId, msg.sender, newDesign.payoutAddress, newDesign.metadataCID);
        return newStickerId;
    }

    function _checkGoodStandingPublisher(address _publisher) internal view returns (bool) {
        if (bannedPublishers[_publisher]) {
            return false;
        }
        return goodStandingPublishers[_publisher];
    }

    function _canModifyStickerDesign(address _publisher, uint256 _stickerId) internal view returns (bool) {
        return _checkGoodStandingPublisher(_publisher) && _stickerDesigns[_stickerId].currentPublisher == _publisher;
    }

    function setStickerPublisher(uint256 _stickerId, address _recipient) public {
        if (!_canModifyStickerDesign(msg.sender, _stickerId)) {
            revert PublisherPermissionsIssue();
        }
        address originalPublisher = _stickerDesigns[_stickerId].originalPublisher;
        _stickerDesigns[_stickerId].currentPublisher = _recipient;
        emit StickerPublisherChanged(_stickerId, originalPublisher, _recipient);
    }

    function setStickerPayoutAddress(uint256 _stickerId, address _recipient) public {
        if (!_canModifyStickerDesign(msg.sender, _stickerId)) {
            revert PublisherPermissionsIssue();
        }
        _stickerDesigns[_stickerId].payoutAddress = _recipient;
    }

    function setStickerPrice(uint256 _stickerId, uint256 _paymentMethodId, uint64 _price) public {
        if (!_canModifyStickerDesign(msg.sender, _stickerId)) {
            revert PublisherPermissionsIssue();
        }
        if ((_paymentMethodId != 0) &&
            (paymentMethodContract.getPaymentMethod(_paymentMethodId) == IERC20(address(0)))) {
                revert InvalidPaymentMethodId(_paymentMethodId);
        }
        _stickerDesigns[_stickerId].paymentMethodId = _paymentMethodId;
        _stickerDesigns[_stickerId].price = _price;
        emit StickerPriceSet(_stickerId, _paymentMethodId, _price);
    }

    function _isCappedStickerDesign(uint256 _stickerId) private view returns (bool) {
        return (_stickerDesigns[_stickerId].endTime > 0 &&
                _stickerDesigns[_stickerId].endTime < block.timestamp);
    }

    function setStickerEndTime(uint256 _stickerId, uint64 _endTime) public {
        if (!_canModifyStickerDesign(msg.sender, _stickerId)) {
            revert PublisherPermissionsIssue();
        }
        if (_endTime < block.timestamp) {
            revert InvalidEndTime();
        }
        if (_isCappedStickerDesign(_stickerId)) {
            revert CannotModifyEndTime();
        }
        _stickerDesigns[_stickerId].endTime = _endTime;
        emit StickerEndTimeChanged(_stickerId, _endTime);
    }

    function capSticker(uint256 _stickerId) public {
        if (!_canModifyStickerDesign(msg.sender, _stickerId)) {
            revert PublisherPermissionsIssue();
        }
        if (_isCappedStickerDesign(_stickerId)) {
            revert CannotModifyEndTime();
        }
        _stickerDesigns[_stickerId].endTime = uint64(block.timestamp);
        emit StickerCapped(_stickerId);
    }

    function setStickerLimitToHolders(uint256 _stickerId, address _holders) public {
        if (!_canModifyStickerDesign(msg.sender, _stickerId)) {
            revert PublisherPermissionsIssue();
        }
        _stickerDesigns[_stickerId].limitToHolders = _holders;
    }

    // Admin methods

    function _persistAdminFeeRecipient(address newRecipient) internal {
        if (newRecipient == address(0)) {
            revert InvalidAccount();
        }
        adminFeeRecipient = payable(newRecipient);
        emit AdminFeeRecipientChanged(newRecipient);
    }

    // set payment method contract, ensuring it is not the zero address
    function setPaymentMethodContract(IPaymentMethod _payments) external onlyOwner {
        if (address(_payments) == address(0)) {
            revert InvalidAccount();
        }
        paymentMethodContract = _payments;
    }

    function setAdminFeeRecipient(address _recipient) external onlyOwner {
        _persistAdminFeeRecipient(_recipient);
    }

    function setpublisherReputationFee(uint256 _fee) external onlyOwner {
        publisherReputationFee = _fee;
        emit PublisherReputationFeeChanged(_fee);
    }

    function setstickerRegistrationFee(uint256 _fee) external onlyOwner {
        stickerRegistrationFee = _fee;
        emit StickerRegistrationFeeChanged(_fee);
    }

    function banPublishers(address[] calldata _publishers, bool undoBan) external onlyOwner {
        for (uint256 i = 0; i < _publishers.length; i++) {
            bannedPublishers[_publishers[i]] = !undoBan;
            if (!undoBan) {
                goodStandingPublishers[_publishers[i]] = false;
            }
        }
    }

    function banStickerDesigns(uint256[] calldata _stickerIds, bool undoBan) external onlyOwner {
        for (uint256 i = 0; i < _stickerIds.length; i++) {
            bannedStickerDesigns[_stickerIds[i]] = !undoBan;
        }
    }

    function forwardFunds() external {
        adminFeeRecipient.transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}

}
