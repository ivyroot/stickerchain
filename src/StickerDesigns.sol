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
    event StickerCapped(uint256 indexed stickerId);

    error PublisherIsBanned();
    error InvalidPublishingFee(uint256 requiredFee);

    constructor() Ownable(msg.sender) {}

    mapping(uint256 => StickerDesign) stickerDesigns;
    uint256 public nextStickerDesignId = 1;

    // New Publishers pay the publisher reputation fee on first publish.
    uint256 public publisherReputationFee = 0.002 ether;
    mapping (address => bool) public goodStandingPublishers;
    // If a Publisher is banned they can no longer create new stickers.
    mapping (address => bool) public bannedPublishers;

    // If an individual sticker design is banned, it will not be returned by the contract.
    uint256 public stickerRegistrationFee = 0.0005 ether;
    mapping (uint256 => bool) public bannedStickerDesigns;

    function isGoodStandingPublisher(address _publisher) external view returns (bool) {
        return isPublisherInGoodStanding(_publisher);
    }

    function readStickerDesign(uint256 _stickerId) internal view returns (StickerDesign memory) {
        if (bannedStickerDesigns[_stickerId] == true) {
            return StickerDesign(address(0), address(0), 0, 0, 0, 0, "");
        } else {
            return stickerDesigns[_stickerId];
        }
    }

    function getStickerDesign(uint256 _stickerId) external view returns (StickerDesign memory) {
        return readStickerDesign(_stickerId);
    }

    function getStickerDesigns(uint256[] calldata _stickerIds) external view returns (StickerDesign[] memory) {
        StickerDesign[] memory designs = new StickerDesign[](_stickerIds.length);
        for (uint256 i = 0; i < _stickerIds.length; i++) {
            designs[i] = readStickerDesign(_stickerIds[i]);
        }
        return designs;
    }

    function publishStickerDesign(NewStickerDesign calldata newDesign) external payable returns(uint256) {
        if (bannedPublishers[msg.sender]) {
            revert PublisherIsBanned();
        }
        bool firstSticker = !goodStandingPublishers[msg.sender];
        uint256 requiredFee = firstSticker ? publisherReputationFee + stickerRegistrationFee : stickerRegistrationFee;
        if (msg.value != requiredFee) {
            revert InvalidPublishingFee(requiredFee);
        }
        uint256 newStickerId = nextStickerDesignId;
        uint64 endTime = uint64(newDesign.limitTime == 0 ? 0 : block.timestamp + newDesign.limitTime);
        stickerDesigns[newStickerId] = StickerDesign({
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

    // Publisher methods
    function isPublisherInGoodStanding(address _publisher) internal view returns (bool) {
        if (bannedPublishers[_publisher]) {
            return false;
        }
        return goodStandingPublishers[_publisher];
    }

    function canModifyStickerDesign(address _publisher, uint256 _stickerId) internal view returns (bool) {
        return isPublisherInGoodStanding(_publisher) && stickerDesigns[_stickerId].publisher == _publisher;
    }

    function transferStickerOwnership(uint256 _stickerId, address _recipient) public {
        if (!canModifyStickerDesign(msg.sender, _stickerId)) {
            revert PublisherIsBanned();
        }
        stickerDesigns[_stickerId].publisher = _recipient;
        emit StickerOwnershipTransferred(msg.sender, _recipient, _stickerId);
    }

    function setStickerPrice(uint256 _stickerId, uint64 _price) public {
        if (!canModifyStickerDesign(msg.sender, _stickerId)) {
            revert PublisherIsBanned();
        }
        stickerDesigns[_stickerId].price = _price;
        emit StickerPriceSet(_stickerId, _price);
    }

    function capSticker(uint256 _stickerId) public {
        if (!canModifyStickerDesign(msg.sender, _stickerId)) {
            revert PublisherIsBanned();
        }
        stickerDesigns[_stickerId].endTime = uint64(block.timestamp);
        emit StickerCapped(_stickerId);
    }

    // Admin methods

    function setpublisherReputationFee(uint256 _fee) external onlyOwner {
        publisherReputationFee = _fee;
    }

    function setstickerRegistrationFee(uint256 _fee) external onlyOwner {
        stickerRegistrationFee = _fee;
    }

    function banStickerDesigns(uint256[] calldata _stickerIds, bool undoBan) external onlyOwner {
        for (uint256 i = 0; i < _stickerIds.length; i++) {
            bannedStickerDesigns[_stickerIds[i]] = !undoBan;
        }
    }

    function banPublishers(address[] calldata _publishers, bool undoBan) external onlyOwner {
        for (uint256 i = 0; i < _publishers.length; i++) {
            bannedPublishers[_publishers[i]] = !undoBan;
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


}
