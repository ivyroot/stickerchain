// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

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

contract StickerDesigns is ERC721A, Ownable {
    event StickerDesignPublished(uint256 indexed id, bytes metadataCID, uint256 price, address publisher, address payoutAddress);
    event StickerOwnershipTransferred(address indexed from, address indexed to, uint256 indexed stickerId);
    event StickerPriceSet(uint256 indexed stickerId, uint256 price);
    event StickerCapped(uint256 indexed stickerId);

    error InsufficientPublisherPermissions();
    error InvalidPublishingFee(uint256 requiredFee);

    constructor() ERC721A("StickerDesignz", "STKRS-TEST-DEV") Ownable(msg.sender) {}

    mapping(uint256 => StickerDesign) stickerDesigns;
    uint256 public nextStickerDesignId = 1;

    // all publishers must pay a onetime fee to establish reputation the admin can set this
    // using the setPublisherFee function
    uint256 public publisherFee = 0.002 ether;
    uint256 public newStickerFee = 0.0005 ether;

    mapping (address => bool) public goodStandingPublishers;
    mapping (address => bool) public bannedPublishers;


    function getStickerDesign(uint256 _stickerId) external view returns (StickerDesign memory) {
        return stickerDesigns[_stickerId];
    }

    function getStickerDesigns(uint256[] calldata _stickerIds) external view returns (StickerDesign[] memory) {
        StickerDesign[] memory designs = new StickerDesign[](_stickerIds.length);
        for (uint256 i = 0; i < _stickerIds.length; i++) {
            designs[i] = stickerDesigns[_stickerIds[i]];
        }
        return designs;
    }

    // on first sticker creation new addresses pay the publisher fee and have their address added to the goodStandingPublishers mapping
    // if a publisher is banned they can no longer create new stickers
    function publishStickerDesign(NewStickerDesign calldata newDesign) external payable returns(uint256) {
        if (bannedPublishers[msg.sender]) {
            revert InsufficientPublisherPermissions();
        }
        bool firstSticker = !goodStandingPublishers[msg.sender];
        uint256 requiredFee = firstSticker ? publisherFee + newStickerFee : newStickerFee;
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
            revert InsufficientPublisherPermissions();
        }
        stickerDesigns[_stickerId].publisher = _recipient;
        emit StickerOwnershipTransferred(msg.sender, _recipient, _stickerId);
    }

    function setStickerPrice(uint256 _stickerId, uint64 _price) public {
        if (!canModifyStickerDesign(msg.sender, _stickerId)) {
            revert InsufficientPublisherPermissions();
        }
        stickerDesigns[_stickerId].price = _price;
        emit StickerPriceSet(_stickerId, _price);
    }

    function capSticker(uint256 _stickerId) public {
        if (!canModifyStickerDesign(msg.sender, _stickerId)) {
            revert InsufficientPublisherPermissions();
        }
        stickerDesigns[_stickerId].endTime = uint64(block.timestamp);
        emit StickerCapped(_stickerId);
    }

    // Admin methods

    function setPublisherFee(uint256 _fee) external onlyOwner {
        publisherFee = _fee;
    }

    function setNewStickerFee(uint256 _fee) external onlyOwner {
        newStickerFee = _fee;
    }

    function banPublisher(address _publisher) external onlyOwner {
        bannedPublishers[_publisher] = true;
    }

    function unbanPublisher(address _publisher) external onlyOwner {
        bannedPublishers[_publisher] = false;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


}
