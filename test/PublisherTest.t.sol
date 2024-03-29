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
        bytes memory metadataCID = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';
        uint256 price = 0.1 ether;
        address publisher = address(this);
        address payoutAddress = publisher;
        vm.deal(publisher, 20 ether);
        vm.prank(publisher);

        uint256 feeAmount = publisherFee + newStickerFee;
        uint256 newStickerId = stickerDesigns.createStickerDesign{value: feeAmount}(price, payoutAddress, metadataCID);
        StickerDesign memory sticker = stickerDesigns.getStickerDesign(newStickerId);
        assertEq(sticker.metadataCID, metadataCID);
        assertEq(sticker.price, price);
        assertEq(sticker.publisher, publisher);
        assertEq(sticker.payoutAddress, payoutAddress);


    }

    // Test checking contract reverts if insufficient fee is sent for a first-time publisher
    function testFirstTimePublisherInsufficientFee() public {
        bytes memory metadataCID = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';
        uint256 price = 0.1 ether;
        address publisher = address(this);
        address payoutAddress = address(this);
        vm.deal(publisher, 20 ether);
        vm.prank(publisher);

        uint256 incorrectFeeAmount = newStickerFee;
        vm.expectRevert(
            abi.encodeWithSelector(StickerDesigns.InvalidPublishingFee.selector, publisherFee + newStickerFee)
        );
        stickerDesigns.createStickerDesign{value: incorrectFeeAmount}( price, payoutAddress, metadataCID);
    }

    // Test second sticker creation with the fee for a returning publisher
    function testReturningPublisherFee() public {
        bytes memory metadata1CID = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';
        bytes memory metadata2CID = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54422196e3d342611';
        uint256 price = 0.0 ether;
        address publisher = address(this);
        address payoutAddress = publisher;
        vm.deal(publisher, 20 ether);
        vm.prank(publisher);

        uint256 newStickerId1 =  stickerDesigns.createStickerDesign{value: publisherFee + newStickerFee}(price, payoutAddress, metadata1CID);
        uint256 newStickerId2 = stickerDesigns.createStickerDesign{value: newStickerFee}(price, payoutAddress, metadata2CID);
        uint256[] memory stickerIds = new uint256[](2);
        stickerIds[0] = newStickerId1;
        stickerIds[1] = newStickerId2;
        StickerDesign[] memory stickers = stickerDesigns.getStickerDesigns(stickerIds);
        assertEq(stickers.length, 2);
        assertEq(stickers[0].metadataCID, metadata1CID);
        assertEq(stickers[0].price, price);
        assertEq(stickers[0].publisher, publisher);
        assertEq(stickers[0].payoutAddress, payoutAddress);
        assertEq(stickers[1].metadataCID, metadata2CID);
        assertEq(stickers[1].price, price);
        assertEq(stickers[1].publisher, publisher);
        assertEq(stickers[1].payoutAddress, payoutAddress);
    }

}
