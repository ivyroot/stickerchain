// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol";
import "../src/StickerChain.sol";

contract PlayerSlapTest is Test {
    StickerDesigns stickerDesigns;
    StickerChain stickerChain;
    uint256 public publisherFee = 0.002 ether;
    uint256 public newStickerFee = 0.0005 ether;
    uint256 public slapFee = 0.001 ether;
    uint256 private exampleStickerId1;
    address add1 = address(0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97);
    address add2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address add3 = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    // Setup function to deploy the StickerDesigns contract before each test
    function setUp() public {
        stickerDesigns = new StickerDesigns(msg.sender, 0.002 ether, 0.0005 ether);
        stickerChain = new StickerChain(slapFee);

        bytes memory metadataCID = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';
        uint256 price = 0.1 ether;
        address publisher = address(this);
        vm.deal(publisher, 20 ether);
        vm.prank(publisher);

        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(price),
            limitCount: 8,
            limitTime: 0,
            metadataCID: metadataCID
        });

        uint256 feeAmount = publisherFee + newStickerFee;
        exampleStickerId1 = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);
    }


    // Test slapping a sticker on a place
    function testSlapOneSticker() public {
        vm.deal(add1, 20 ether);
        vm.startPrank(add1);
        stickerChain.slap{value: slapFee}(7147618599, exampleStickerId1, 1);
        Slap memory slap = stickerChain.getSlap(1);
        assertEq(slap.stickerId, exampleStickerId1);
        assertEq(slap.placeId, 7147618599);
        assertEq(slap.player, add1);
        assertEq(slap.slappedAt, block.timestamp);
    }

    function testGetPlaceSlapsWithOneSticker() public {
        vm.deal(add1, 2 ether);
        vm.prank(add1);
        stickerChain.slap{value: slapFee}(7147618599, exampleStickerId1, 1);
        (uint total, Slap[] memory slaps) = stickerChain.getPlaceSlaps(7147618599, 0, 0);
        assertEq(total, 1);
        // assertEq(slaps[0].stickerId, exampleStickerId1);
        // assertEq(slaps[0].player, add1);
        // assertEq(slaps[0].placeId, 7147618599);
    }
}