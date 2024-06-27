// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol";
import "../src/StickerChain.sol";
import "../src/PaymentMethod.sol";

contract PlayerSlapTest is Test {
    StickerDesigns stickerDesigns;
    PaymentMethod paymentMethod;
    StickerChain stickerChain;
    uint256 public publisherFee = 0.002 ether;
    uint256 public newStickerFee = 0.0005 ether;
    uint256 public slapFee = 0.001 ether;
    uint256 private exampleStickerId1;
    uint256 private exampleStickerId2;
    uint256 private placeIdUnionSquare = 7147618599;
    uint256 private placeIdHollywoodSign = 4126216247;
    address adminAddress = address(this);
    address address1 = address(0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97);
    address address2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address address3 = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    function setUp() public {
        stickerDesigns = new StickerDesigns(msg.sender, 0.002 ether, 0.0005 ether);
        paymentMethod = new PaymentMethod(adminAddress, 0.001 ether);
        stickerChain = new StickerChain(slapFee, payable(address(stickerDesigns)), payable(address(paymentMethod)));

        bytes memory metadataCID = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';
        uint256 price = 0.1 ether;
        address publisher = adminAddress;
        vm.deal(publisher, 20 ether);
        vm.prank(publisher);

        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(price),
            paymentMethodId: 0,
            limitCount: 8,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadataCID
        });

        uint256 feeAmount = publisherFee + newStickerFee;
        exampleStickerId1 = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);

        NewStickerDesign memory newStickerDesign2 = NewStickerDesign({
            payoutAddress: address3,
            price: uint64(0.0 ether),
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadataCID
        });
        exampleStickerId2 = stickerDesigns.publishStickerDesign{value: newStickerFee}(newStickerDesign2);

    }

    // validate cannot slap invalid sticker id
    function testSlapInvalidStickerIdTooLow() public {
        vm.deal(address1, 20 ether);
        vm.startPrank(address1);
        NewSlap memory newSlap = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: 0,
            size: 1
        });
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.SlapNotAllowed.selector, 0)
        );
        stickerChain.slap{value: slapFee}(newSlap);
    }

    function testSlapInvalidStickerTooHigh() public {
        uint nextStickerId = stickerDesigns.nextStickerDesignId();
        vm.deal(address1, 20 ether);
        vm.startPrank(address1);
        NewSlap memory newSlap = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: nextStickerId,
            size: 1
        });
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.SlapNotAllowed.selector, nextStickerId)
        );
        stickerChain.slap{value: slapFee}(newSlap);
    }

    // test cannot slap banned sticker design
    function testSlapBannedSticker() public {
        uint[] memory banStickerIds = new uint[](1);
        banStickerIds[0] = exampleStickerId1;
        stickerDesigns.banStickerDesigns(banStickerIds, false);
        vm.deal(address1, 20 ether);
        vm.startPrank(address1);
        NewSlap memory newSlap = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId1,
            size: 1
        });
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.SlapNotAllowed.selector, exampleStickerId1)
        );
        stickerChain.slap{value: slapFee}(newSlap);
    }

    // test banned player cannot slap
    function testBannedPlayerCannotSlap() public {
        address[] memory banPlayers = new address[](1);
        banPlayers[0] = address1;
        stickerChain.banPlayers(banPlayers, false);
        vm.deal(address1, 20 ether);
        vm.startPrank(address1);
        NewSlap memory newSlap = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId1,
            size: 1
        });
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.PlayerIsBanned.selector)
        );
        stickerChain.slap{value: slapFee}(newSlap);
    }

    // Test slapping a sticker and accessing via slap id
    function testSlapOneStickerAndGetIt() public {
        vm.deal(address1, 20 ether);
        vm.startPrank(address1);
        NewSlap memory newSlap = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId1,
            size: 1
        });
        stickerChain.slap{value: slapFee}(newSlap);
        Slap memory slap = stickerChain.getSlap(1);
        assertEq(slap.stickerId, exampleStickerId1);
        assertEq(slap.placeId, placeIdUnionSquare);
        assertEq(slap.player, address1);
        assertEq(slap.slappedAt, block.timestamp);
    }

    function testSlapTwoStickersAndGetThem() public {
        vm.deal(address1, 20 ether);
        vm.startPrank(address1);
        NewSlap memory newSlap1 = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId1,
            size: 1
        });
        NewSlap memory newSlap2 = NewSlap({
            placeId: placeIdHollywoodSign,
            stickerId: exampleStickerId2,
            size: 1
        });
        stickerChain.slap{value: slapFee}(newSlap1);
        stickerChain.slap{value: slapFee}(newSlap2);
        uint[] memory slapIds = new uint[](2);
        slapIds[0] = 1;
        slapIds[1] = 2;
        Slap[] memory slaps = stickerChain.getSlaps(slapIds);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].slappedAt, block.timestamp);
        assertEq(slaps[1].stickerId, exampleStickerId2);
        assertEq(slaps[1].placeId, placeIdHollywoodSign);
        assertEq(slaps[1].player, address1);
        assertEq(slaps[1].slappedAt, block.timestamp);
    }

    // test slapping two stickers via multiSlap
    function testSlapTwoStickersViaMultiSlap() public {
        vm.deal(address1, 20 ether);
        vm.startPrank(address1);
        NewSlap[] memory newSlaps = new NewSlap[](2);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId1,
            size: 1
        });
        newSlaps[1] = NewSlap({
            placeId: placeIdHollywoodSign,
            stickerId: exampleStickerId2,
            size: 1
        });

        uint[] memory slapIds = new uint[](2);
        slapIds[0] = stickerChain.nextSlapId();
        slapIds[1] = slapIds[0] + 1;
        stickerChain.multiSlap{value: 2 * slapFee}(newSlaps);
        // validate slaps
        Slap[] memory slaps = stickerChain.getSlaps(slapIds);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].slappedAt, block.timestamp);
        assertEq(slaps[1].stickerId, exampleStickerId2);
        assertEq(slaps[1].placeId, placeIdHollywoodSign);
        assertEq(slaps[1].player, address1);
        assertEq(slaps[1].slappedAt, block.timestamp);
    }


    // test slapping a sticker and then having the design be banned, removing it
    function testSlapTwoStickersBanOneAndThenGetThem() public {
        vm.deal(address1, 20 ether);
        vm.startPrank(address1);
        NewSlap memory newSlap1 = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId1,
            size: 1
        });
        NewSlap memory newSlap2 = NewSlap({
            placeId: placeIdHollywoodSign,
            stickerId: exampleStickerId2,
            size: 1
        });
        stickerChain.slap{value: slapFee}(newSlap1);
        stickerChain.slap{value: slapFee}(newSlap2);
        uint[] memory banStickerIds = new uint[](1);
        banStickerIds[0] = exampleStickerId2;
        vm.startPrank(adminAddress);
        stickerDesigns.banStickerDesigns(banStickerIds, false);
        uint[] memory slapIds = new uint[](2);
        slapIds[0] = 1;
        slapIds[1] = 2;
        Slap[] memory slaps = stickerChain.getSlaps(slapIds);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].slappedAt, block.timestamp);
        assertEq(slaps[1].stickerId, 0);
        assertEq(slaps[1].placeId, 0);
        assertEq(slaps[1].player, address(0));
        assertEq(slaps[1].slappedAt, 0);
    }

    // Test slapping a sticker and accessing via place
    function testGetPlaceSlapsWithOneSticker() public {
        vm.deal(address1, 2 ether);
        vm.prank(address1);
        NewSlap memory newSlap1 = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId1,
            size: 1
        });
        stickerChain.slap{value: slapFee}(newSlap1);
        // load stickers from place
        (uint total, Slap[] memory slaps) = stickerChain.getPlaceSlaps(placeIdUnionSquare, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
    }

    function testGetPlaceSlapsWithTwoStickers() public {
        vm.deal(address1, 1 ether);
        vm.deal(address2, 1 ether);

        NewSlap memory newSlap1 = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId1,
            size: 1
        });

        // slap first sticker
        uint timestamp1 = 1717108737;
        vm.warp(timestamp1);
        vm.prank(address1);
        stickerChain.slap{value: slapFee}(newSlap1);

        // slap second sticker
        vm.roll(50 + block.number);
        vm.warp(2600 + block.timestamp);
        uint timestamp2 = block.timestamp;
        vm.prank(address2);
        stickerChain.slap{value: slapFee}(newSlap1);

        // load stickers from place
        (uint total, Slap[] memory slaps) = stickerChain.getPlaceSlaps(placeIdUnionSquare, 0, 0);
        assertEq(total, 2);

        // check latest slap is most recent
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address2);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        assertEq(slaps[0].slappedAt, timestamp2);

        assertEq(slaps[1].stickerId, exampleStickerId1);
        assertEq(slaps[1].player, address1);
        assertEq(slaps[1].placeId, placeIdUnionSquare);

        assertEq(slaps[1].slappedAt, timestamp1);
    }

    function testCreateSlapOfSize2() public {
        vm.deal(address1, 2 ether);
        vm.prank(address1);
        NewSlap memory newSlapSize2 = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId1,
            size: 2
        });

        stickerChain.slap{value: slapFee}(newSlapSize2);
        // load stickers from covered places
        uint total;
        Slap[] memory slaps;
        (total, slaps) = stickerChain.getPlaceSlaps(placeIdUnionSquare, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        (total, slaps) = stickerChain.getPlaceSlaps(7147619623, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        (total, slaps) = stickerChain.getPlaceSlaps(7147619619, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        (total, slaps) = stickerChain.getPlaceSlaps(7147618595, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        // sanity check adjacent place is empty
        (total, slaps) = stickerChain.getPlaceSlaps(7147620647, 0, 0);
        assertEq(total, 0);
    }

    function testCreateSlapOfSize3() public {
        vm.deal(address1, 2 ether);
        vm.prank(address1);
        NewSlap memory newSlapSize3 = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId1,
            size: 3
        });
        stickerChain.slap{value: slapFee}(newSlapSize3);
        // load stickers from covered places
        uint total;
        Slap[] memory slaps;
        (total, slaps) = stickerChain.getPlaceSlaps(placeIdUnionSquare, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        (total, slaps) = stickerChain.getPlaceSlaps(7147619623, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        (total, slaps) = stickerChain.getPlaceSlaps(7147619619, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        (total, slaps) = stickerChain.getPlaceSlaps(7147618595, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        // ring 3
        (total, slaps) = stickerChain.getPlaceSlaps(7147620647, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        (total, slaps) = stickerChain.getPlaceSlaps(7147620643, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        (total, slaps) = stickerChain.getPlaceSlaps(7147620639, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        (total, slaps) = stickerChain.getPlaceSlaps(7147619615, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        (total, slaps) = stickerChain.getPlaceSlaps(7147618591, 0, 0);
        assertEq(total, 1);
        assertEq(slaps[0].stickerId, exampleStickerId1);
        assertEq(slaps[0].player, address1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        // sanity check adjacent place is empty
        (total, slaps) = stickerChain.getPlaceSlaps(7147621671, 0, 0);
        assertEq(total, 0);



    }
}