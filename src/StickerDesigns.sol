// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

struct NewStickerDesign {
    address payoutAddress;
    uint64 price;
    uint64 limitCount;
    uint64 limitTime;
    bytes metadataCID;
}

struct StickerDesign {
    address publisher;
    address payoutAddress;
    uint64 publishedAt;
    uint64 price;
    uint64 limit;
    uint64 endTime;
    bytes metadataCID;
}

contract StickerDesigns is Ownable {
    event StickerDesignPublished(uint256 indexed id, bytes metadataCID, uint256 price, address publisher, address payoutAddress);
    event StickerOwnershipTransferred(address indexed from, address indexed to, uint256 indexed stickerId);
    event StickerPriceSet(uint256 indexed stickerId, uint256 price);
    event StickerEndTimeChanged(uint256 indexed stickerId, uint256 endTime);
    event StickerCapped(uint256 indexed stickerId);

    error PublisherPermissionsIssue();
    error InvalidPublishingFee(uint256 requiredFee);
    error InvalidEndTime();

    uint256 public publisherReputationFee;
    uint256 public stickerRegistrationFee;
    uint256 public nextStickerDesignId = 1;

    mapping (address => bool) public goodStandingPublishers;
    mapping (address => bool) public bannedPublishers;
    mapping (uint256 => bool) public bannedStickerDesigns;
    mapping (uint256 => StickerDesign) private _stickerDesigns;

    constructor(uint _reputationFee, uint _registrationFee) Ownable(msg.sender) {
        publisherReputationFee = _reputationFee;
        stickerRegistrationFee = _registrationFee;
    }


    // View methods

    function getStickerDesign(uint256 _stickerId) external view returns (StickerDesign memory) {
        return _readStickerDesign(_stickerId);
    }

    function getStickerDesigns(uint256[] calldata _stickerIds) external view returns (StickerDesign[] memory) {
        StickerDesign[] memory designs = new StickerDesign[](_stickerIds.length);
        for (uint256 i = 0; i < _stickerIds.length; i++) {
            designs[i] = _readStickerDesign(_stickerIds[i]);
        }
        return designs;
    }

    function _readStickerDesign(uint256 _stickerId) internal view returns (StickerDesign memory) {
        if (bannedStickerDesigns[_stickerId] == true) {
            return StickerDesign(address(0), address(0), 0, 0, 0, 0, "");
        } else {
            return _stickerDesigns[_stickerId];
        }
    }

    function isPublisherInGoodStanding(address _publisher) external view returns (bool) {
        return checkGoodStandingPublisher(_publisher);
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
            publisher: msg.sender,
            payoutAddress: newDesign.payoutAddress,
            publishedAt: uint64(block.timestamp),
            price: newDesign.price,
            limit: newDesign.limitCount,
            endTime: endTime,
            metadataCID: newDesign.metadataCID
        });
        if (firstSticker) {
            goodStandingPublishers[msg.sender] = true;
        }
        nextStickerDesignId++;
        emit StickerDesignPublished(newStickerId, newDesign.metadataCID, newDesign.price, msg.sender, newDesign.payoutAddress);
        return newStickerId;
    }

    function checkGoodStandingPublisher(address _publisher) internal view returns (bool) {
        if (bannedPublishers[_publisher]) {
            return false;
        }
        return goodStandingPublishers[_publisher];
    }

    function _canModifyStickerDesign(address _publisher, uint256 _stickerId) internal view returns (bool) {
        return checkGoodStandingPublisher(_publisher) && _stickerDesigns[_stickerId].publisher == _publisher;
    }

    function transferStickerOwnership(uint256 _stickerId, address _recipient) public {
        if (!_canModifyStickerDesign(msg.sender, _stickerId)) {
            revert PublisherPermissionsIssue();
        }
        _stickerDesigns[_stickerId].publisher = _recipient;
        emit StickerOwnershipTransferred(msg.sender, _recipient, _stickerId);
    }

    function setStickerPrice(uint256 _stickerId, uint64 _price) public {
        if (!_canModifyStickerDesign(msg.sender, _stickerId)) {
            revert PublisherPermissionsIssue();
        }
        _stickerDesigns[_stickerId].price = _price;
        emit StickerPriceSet(_stickerId, _price);
    }

    function setStickerEndTime(uint256 _stickerId, uint64 _endTime) public {
        if (!_canModifyStickerDesign(msg.sender, _stickerId)) {
            revert PublisherPermissionsIssue();
        }
        if (_endTime < block.timestamp) {
            revert InvalidEndTime();
        }
        _stickerDesigns[_stickerId].endTime = _endTime;
        emit StickerEndTimeChanged(_stickerId, _endTime);
    }

    function capSticker(uint256 _stickerId) public {
        if (!_canModifyStickerDesign(msg.sender, _stickerId)) {
            revert PublisherPermissionsIssue();
        }
        _stickerDesigns[_stickerId].endTime = uint64(block.timestamp);
        emit StickerCapped(_stickerId);
    }


    // Admin methods

    function setpublisherReputationFee(uint256 _fee) external onlyOwner {
        publisherReputationFee = _fee;
    }

    function setstickerRegistrationFee(uint256 _fee) external onlyOwner {
        stickerRegistrationFee = _fee;
    }

    function banPublishers(address[] calldata _publishers, bool undoBan) external onlyOwner {
        for (uint256 i = 0; i < _publishers.length; i++) {
            bannedPublishers[_publishers[i]] = !undoBan;
        }
    }

    function banStickerDesigns(uint256[] calldata _stickerIds, bool undoBan) external onlyOwner {
        for (uint256 i = 0; i < _stickerIds.length; i++) {
            bannedStickerDesigns[_stickerIds[i]] = !undoBan;
        }
    }


    // Payout methods

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


}
