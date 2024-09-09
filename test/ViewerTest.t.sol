// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol";
import "../src/StickerChain.sol";
import "../src/PaymentMethod.sol";
import "../src/PayoutMethod.sol";
import "forge-std/console.sol";

contract ViewerTest is Test {
    StickerDesigns stickerDesigns;
    PaymentMethod paymentMethod;
    StickerChain stickerChain;
    PayoutMethod publisherPayoutMethod;
    PayoutMethod objectivePayoutMethod;
    uint256 public publisherFee = 0.002 ether;
    uint256 public newStickerFee = 0.0005 ether;
    address adminAddress = address(this);
    address publisher = 0x541EdA6C1171B1253b01f90678475A3Da5B05745;
    address addressPlayerOne = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256[] private playerOneSlaps;
    address addressPlayerTwo = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint256[] private playerTwoSlaps;
    uint256 public newStickerId1;
    uint256 public newSticker1Price = 0.1 ether;
    uint256 public newStickerId2;
    uint256 private specialTimestamp = 1766620801;
    bytes metadataCID1 = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';
    bytes metadataCID2 = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54422196e3d342611';
    uint256 public slapFee = 0.001 ether;
    uint256 private placeIdUnionSquare = 7147618599;
    uint256 private placeIdHollywoodSign = 4126216247;


    receive() external payable {}
    fallback() external payable {}

    // Setup function to deploy the StickerDesigns contract before each test
    function setUp() public {
        // setup game
        paymentMethod = new PaymentMethod(adminAddress, 0.001 ether);
        stickerDesigns = new StickerDesigns(paymentMethod, adminAddress, 0.002 ether, 0.0005 ether);
        stickerChain = new StickerChain(adminAddress, slapFee, payable(address(stickerDesigns)), payable(address(paymentMethod)));
        publisherPayoutMethod = new PayoutMethod(address(stickerChain), adminAddress);
        objectivePayoutMethod = new PayoutMethod(address(stickerChain), adminAddress);
        stickerChain.setPublisherPayoutMethodContract(payable(address(publisherPayoutMethod)));
        stickerChain.setObjectivePayoutMethodContract(payable(address(objectivePayoutMethod)));
        // deal to actors
        vm.deal(addressPlayerOne, 20 ether);
        vm.deal(addressPlayerTwo, 20 ether);
        vm.deal(publisher, 20 ether);
        vm.startPrank(publisher);
        NewStickerDesign memory newStickerDesign1 = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(newSticker1Price),
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadataCID1
        });
        NewStickerDesign memory newStickerDesign2 = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(0.0 ether),
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadataCID2
        });
        bool inGoodStanding = stickerDesigns.isPublisherInGoodStanding(publisher);
        uint256 feeAmount = inGoodStanding ? newStickerFee : publisherFee + newStickerFee;
        newStickerId1 = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign1);
        newStickerId2 = stickerDesigns.publishStickerDesign{value: newStickerFee}(newStickerDesign2);

        vm.warp(specialTimestamp);
        playerOneDoesSomeSlaps();
        playerTwoDoesSomeSlaps();
    }

    function playerOneDoesSomeSlaps() public  {
        vm.startPrank(addressPlayerOne);
        NewSlap[] memory newSlapsAddress2 = new NewSlap[](2);
        newSlapsAddress2[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: newStickerId1,
            size: 1
        });
        newSlapsAddress2[1] = NewSlap({
            placeId: placeIdHollywoodSign,
            stickerId: newStickerId2,
            size: 1
        });
        uint256[] memory objectivesAddress2;
        PaymentMethodTotal[] memory calculatedCostsAddress2 = stickerChain.costOfSlaps(addressPlayerOne, newSlapsAddress2, objectivesAddress2);
        (addressPlayerOne, newSlapsAddress2, objectivesAddress2);
        assertEq(calculatedCostsAddress2.length, 1);
        assertEq(calculatedCostsAddress2[0].paymentMethodId, 0);
        uint calculatedSlapCostAddress2 = calculatedCostsAddress2[0].total;
        uint[] memory playerOneSlapStatuses;
        (playerOneSlaps, playerOneSlapStatuses) = stickerChain.slap{value: calculatedSlapCostAddress2}(newSlapsAddress2, objectivesAddress2);
        assertEq(playerOneSlaps.length, 2);
        assertEq(playerOneSlaps[0], 1);
        assertEq(playerOneSlaps[1], 2);
        assertEq(playerOneSlapStatuses.length, 2);
        assertEq(playerOneSlapStatuses[0], 0);
        assertEq(playerOneSlapStatuses[1], 0);
    }

    function playerTwoDoesSomeSlaps() public  {
        vm.startPrank(addressPlayerTwo);
        NewSlap[] memory newSlapsAddress2 = new NewSlap[](2);
        newSlapsAddress2[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: newStickerId1,
            size: 1
        });
        newSlapsAddress2[1] = NewSlap({
            placeId: placeIdHollywoodSign,
            stickerId: newStickerId2,
            size: 1
        });
        uint256[] memory objectivesAddress2;
        PaymentMethodTotal[] memory calculatedCostsAddress2 = stickerChain.costOfSlaps(addressPlayerTwo, newSlapsAddress2, objectivesAddress2);
        assertEq(calculatedCostsAddress2.length, 1);
        assertEq(calculatedCostsAddress2[0].paymentMethodId, 0);
        uint calculatedSlapCostAddress2 = calculatedCostsAddress2[0].total;
        uint[] memory playerTwoSlapStatuses;
        (playerTwoSlaps, playerTwoSlapStatuses) = stickerChain.slap{value: calculatedSlapCostAddress2}(newSlapsAddress2, objectivesAddress2);
        assertEq(playerTwoSlaps.length, 2);
        assertEq(playerTwoSlaps[0], 3);
        assertEq(playerTwoSlaps[1], 4);
        assertEq(playerTwoSlapStatuses.length, 2);
        assertEq(playerTwoSlapStatuses[0], 0);
        assertEq(playerTwoSlapStatuses[1], 0);
    }

    function testViewSingleStickerDesign() public view {
        StickerDesign memory sticker = stickerDesigns.getStickerDesign(newStickerId1);
        assertEq(sticker.metadataCID, metadataCID1);
        assertEq(sticker.price, uint64(0.1 ether));
        assertEq(sticker.currentPublisher, publisher);
        assertEq(sticker.originalPublisher, publisher);
        assertEq(sticker.payoutAddress, address(0));
    }

    function testViewTwoStickerDesigns() public view {
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

    function testGetStickerDesigns() public view {
        uint256 start = 1;
        uint256 count = 2;
        StickerDesign[] memory stickers = stickerDesigns.getStickerDesigns(start, count);
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

    // Test getStickerDesigns function with start of 100 and count of 1
    function testGetStickerDesignsOutOfRange() public {
        uint256 start = 100;
        uint256 count = 1;
        vm.expectRevert(abi.encodeWithSignature("InvalidStickerDesignId(uint256)", start));
        stickerDesigns.getStickerDesigns(start, count);
    }

    // call getStickerDesigns with start of 0 and length of 0
    function testGetStickerDesignsZeroLength() public view {
        uint256 start = 0;
        uint256 count = 0;
        StickerDesign[] memory stickers = stickerDesigns.getStickerDesigns(start, count);
        assertEq(stickers.length, 0);
    }

    // Test getStickerDesigns function with array of ids
    function testGetStickerDesignsArray() public view {
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

    // Test getSlaps function
    function testGetSlaps() public view {
        uint256 start = 1;
        uint256 count = 3;
        Slap[] memory slaps = stickerChain.getSlaps(start, count);
        assertEq(slaps.length, 3);
        // Assuming the first 3 slaps have been set up in the test environment
        // with known properties for assertion
        assertEq(slaps[0].slapId, 1);
        assertEq(slaps[0].stickerId, 1);
        assertEq(slaps[0].placeId, placeIdUnionSquare);
        assertEq(slaps[0].height, 1);
        assertEq(slaps[0].slappedAt, specialTimestamp);
        assertEq(slaps[0].size, 1);
        assertEq(slaps[0].player, addressPlayerOne);

        assertEq(slaps[1].slapId, 2);
        assertEq(slaps[1].stickerId, 2);
        assertEq(slaps[1].placeId, placeIdHollywoodSign);
        assertEq(slaps[1].height, 1);
        assertEq(slaps[1].slappedAt, specialTimestamp);
        assertEq(slaps[1].size, 1);
        assertEq(slaps[1].player, addressPlayerOne);

        assertEq(slaps[2].slapId, 3);
        assertEq(slaps[2].stickerId, 1);
        assertEq(slaps[2].placeId, placeIdUnionSquare);
        assertEq(slaps[2].height, 2);
        assertEq(slaps[2].slappedAt, specialTimestamp);
        assertEq(slaps[2].size, 1);
        assertEq(slaps[2].player, addressPlayerTwo);
    }

    // Test getSlaps function with invalid parameters
    function testGetSlapsInvalidParameters() public {
        uint256 start = 100;
        uint256 count = 3;
        vm.expectRevert(abi.encodeWithSignature("InvalidStart()"));
        stickerChain.getSlaps(start, count);
    }

    // call getSlaps witih start of 0 and length of 0
    function testGetSlapsZeroLength() public view {
        uint256 start = 0;
        uint256 count = 0;
        Slap[] memory slaps = stickerChain.getSlaps(start, count);
        assertEq(slaps.length, 0);
    }

}
