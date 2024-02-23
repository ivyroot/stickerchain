// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol"; // Adjust the path as necessary

contract StickerDesignsTest is Test {
    StickerDesigns stickerDesigns;
    uint256 public publisherFee = 0.002 ether;
    uint256 public newStickerFee = 0.0005 ether;

    // Setup function to deploy the StickerDesigns contract before each test
    function setUp() public {
        stickerDesigns = new StickerDesigns();
    }

    // Test creating a sticker design with the fee for a first-time publisher
    function testFirstTimePublisherFee() public {
        uint256 imageCID = 123456; // Example CID
        uint256 metadataCID = 654321; // Example CID
        uint256 price = 0.1 ether;
        address publisher = address(this);
        address payoutAddress = publisher;
        vm.deal(publisher, 20 ether);
        vm.prank(publisher);

        uint256 feeAmount = publisherFee + newStickerFee;
        uint256 newStickerId = stickerDesigns.createStickerDesign{value: feeAmount}(imageCID, metadataCID, price, payoutAddress);
        StickerDesign memory sticker = stickerDesigns.getStickerDesign(newStickerId);
        assertEq(sticker.imageCID, imageCID);
        assertEq(sticker.metadataCID, metadataCID);
        assertEq(sticker.price, price);
        assertEq(sticker.publisher, publisher);
        assertEq(sticker.payoutAddress, payoutAddress);


    }

    // Test checking contract reverts if insufficient fee is sent for a first-time publisher
    function testFirstTimePublisherInsufficientFee() public {
        uint256 imageCID = 123456; // Example CID
        uint256 metadataCID = 654321; // Example CID
        uint256 price = 0.1 ether;
        address publisher = address(this);
        address payoutAddress = address(this);
        vm.deal(publisher, 20 ether);
        vm.prank(publisher);

        uint256 incorrectFeeAmount = newStickerFee;
        vm.expectRevert(
            abi.encodeWithSelector(StickerDesigns.InvalidPublishingFee.selector, publisherFee + newStickerFee)
        );
        stickerDesigns.createStickerDesign{value: incorrectFeeAmount}(imageCID, metadataCID, price, payoutAddress);
    }

}
