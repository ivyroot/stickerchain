// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/StickerDesigns.sol"; // Adjust the path as necessary

contract ViewerTest is Test {
    StickerDesigns stickerDesigns;
    uint256 public publisherFee = 0.002 ether;
    uint256 public newStickerFee = 0.0005 ether;
    address publisher = 0x541EdA6C1171B1253b01f90678475A3Da5B05745;
    uint256 public newStickerId1;
    uint256 public newStickerId2;
    bytes metadataCID1 = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';
    bytes metadataCID2 = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54422196e3d342611';


    // Setup function to deploy the StickerDesigns contract before each test
    function setUp() public {
        stickerDesigns = new StickerDesigns(0.002 ether, 0.0005 ether);
        vm.deal(publisher, 20 ether);
        vm.startPrank(publisher);
        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(0.1 ether),
            limitCount: 0,
            limitTime: 0,
            metadataCID: metadataCID1
        });
        NewStickerDesign memory newStickerDesign2 = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(0.0 ether),
            limitCount: 0,
            limitTime: 0,
            metadataCID: metadataCID2
        });
        bool inGoodStanding = stickerDesigns.isPublisherInGoodStanding(publisher);
        uint256 feeAmount = inGoodStanding ? newStickerFee : publisherFee + newStickerFee;
        newStickerId1 = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);
        newStickerId2 = stickerDesigns.publishStickerDesign{value: newStickerFee}(newStickerDesign2);
    }

    // Test publishing a sticker design with the fee for a first-time publisher
    function testViewSingleStickerDesign() public {
        StickerDesign memory sticker = stickerDesigns.getStickerDesign(newStickerId1);
        assertEq(sticker.metadataCID, metadataCID1);
        assertEq(sticker.price, uint64(0.1 ether));
        assertEq(sticker.currentPublisher, publisher);
        assertEq(sticker.originalPublisher, publisher);
        assertEq(sticker.payoutAddress, address(0));
    }

    //
    function testViewTwoStickerDesigns() public {
        uint256[] memory stickerIds = new uint256[](2);
        stickerIds[0] = newStickerId1;
        stickerIds[1] = newStickerId2;
        StickerDesign[] memory stickers = stickerDesigns.getStickerDesigns(stickerIds);
        assertEq(stickers.length, 2);
        assertEq(stickers[0].price, uint64(0.1 ether));
        assertEq(stickers[0].currentPublisher, publisher);
        assertEq(stickers[0].originalPublisher, publisher);
        assertEq(stickers[0].payoutAddress, address(0));
        assertEq(stickers[1].price, uint64(0.0 ether));
        assertEq(stickers[1].currentPublisher, publisher);
        assertEq(stickers[1].originalPublisher, publisher);
        assertEq(stickers[1].payoutAddress, address(0));
        assertEq(stickers[0].metadataCID, metadataCID1);
        assertEq(stickers[1].metadataCID, metadataCID2);
    }

}
