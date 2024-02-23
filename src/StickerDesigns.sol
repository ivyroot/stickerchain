// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

struct StickerDesign {
    uint256 imageCID;
    uint256 metadataCID;
    uint256 price;
    address publisher;
    address payoutAddress;
}


contract StickerDesigns is ERC721A, Ownable {
    event StickerDesignCreated(uint256 indexed id, uint256 imageCID, uint256 metadataCID, uint256 price, address publisher, address payoutAddress);
    event StickerOwnershipTransferred(address indexed from, address indexed to, uint256 indexed stickerId);

    constructor() ERC721A("StickerDesignz", "STKRS-TEST-DEV") Ownable(msg.sender) {}

    mapping(uint256 => StickerDesign) public stickerDesigns;
    uint256 public nextStickerDesignId = 0;

    // all publishers must pay a onetime fee to establish reputation the admin can set this
    // using the setPublisherFee function
    uint256 public publisherFee = 0.002 ether;
    uint256 public newStickerFee = 0.0005 ether;

    mapping (address => bool) public goodStandingPublishers;
    mapping (address => bool) public bannedPublishers;

    function mint(uint256 quantity) external payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }

    // on first sticker creation new addresses pay the publisher fee and have their address added to the goodStandingPublishers mapping
    // if a publisher is banned they can no longer create new stickers
    function createStickerDesign(uint256 _imageCID, uint256 _metadataCID, uint256 _price, address _payoutAddress) external payable {
        require(!bannedPublishers[msg.sender], "You are banned from creating new stickers");
        bool firstSticker = !goodStandingPublishers[msg.sender];

        if (firstSticker) {
            require(msg.value == publisherFee + newStickerFee, "Incorrect fee for first sticker");
        }else{
            require(msg.value == newStickerFee, "Incorrect fee for new sticker");
        }

        stickerDesigns[nextStickerDesignId] = StickerDesign({
            imageCID: _imageCID,
            metadataCID: _metadataCID,
            price: _price,
            publisher: msg.sender,
            payoutAddress: _payoutAddress
        });

        if (firstSticker) {
            goodStandingPublishers[msg.sender] = true;
        }

        nextStickerDesignId++;

        emit StickerDesignCreated(nextStickerDesignId, _imageCID, _metadataCID, _price, msg.sender, _payoutAddress);
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

    // transfer sticker ownership
    function transferStickerOwnership(uint256 _stickerId, address _recipient) public {
        require(canModifyStickerDesign(msg.sender, _stickerId), "You are not allowed to modify sticker");
        stickerDesigns[_stickerId].publisher = _recipient;
        emit StickerOwnershipTransferred(msg.sender, _recipient, _stickerId);
    }

    // set sticker price
    function setStickerPrice(uint256 _stickerId, uint256 _price) public {
        require(canModifyStickerDesign(msg.sender, _stickerId), "You are not allowed to modify sticker");
        stickerDesigns[_stickerId].price = _price;
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
