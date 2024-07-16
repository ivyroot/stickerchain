// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol";
import "../src/PaymentMethod.sol";
import "../src/PayoutMethod.sol";
import "../src/StickerChain.sol";

contract PayoutTest is Test {
    StickerDesigns stickerDesigns;
    PaymentMethod paymentMethod;
    StickerChain stickerChain;
    PayoutMethod publisherPayoutMethod;
    PayoutMethod objectivePayoutMethod;
    uint256 public publisherFee = 0.002 ether;
    uint256 public newStickerFee = 0.0005 ether;
    uint256 public slapFee = 0.001 ether;
    uint256 private placeIdUnionSquare = 7147618599;
    address private adminAddress = address(this);
    address publisher1 = address(0x0B5abAA1548b136661114D0016A9519287B026e2);
    address player1 = address(0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97);
    address player2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address dev1 = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    bytes public metadataCID1 = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';

    receive() external payable {}
    fallback() external payable {}

    // Setup function to deploy the StickerDesigns contract before each test
    function setUp() public {
        vm.deal(adminAddress, 20 ether);
        vm.deal(publisher1, 1 ether);
        vm.deal(player1, 20 ether);
        vm.deal(player2, 20 ether);
        vm.deal(dev1, 1 ether);
        paymentMethod = new PaymentMethod(adminAddress, 0.001 ether);
        stickerDesigns = new StickerDesigns(paymentMethod, adminAddress, 0.002 ether, 0.0005 ether);
        stickerChain = new StickerChain(adminAddress, slapFee, payable(address(stickerDesigns)), payable(address(paymentMethod)));
        publisherPayoutMethod = new PayoutMethod(address(stickerChain), adminAddress);
        publisherPayoutMethod.setAdminFee(address(0), 500);
        objectivePayoutMethod = new PayoutMethod(address(stickerChain), adminAddress);
        stickerChain.setPublisherPayoutMethodContract(payable(address(publisherPayoutMethod)));
        stickerChain.setObjectivePayoutMethodContract(payable(address(objectivePayoutMethod)));
    }

    // Test publishing a free sticker and getting protocol fees when it is slapped
    function testPublishFreeStickerAndReceiveProtocolFeePayout() public {
        vm.startPrank(publisher1);

        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: 0,
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadataCID1
        });

        uint256 feeAmount = publisherFee + newStickerFee;
        uint256 newStickerId = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);
        StickerDesign memory sticker = stickerDesigns.getStickerDesign(newStickerId);
        assertEq(sticker.metadataCID, metadataCID1);
        assertEq(sticker.price, 0);
        assertEq(sticker.originalPublisher, publisher1);
        assertEq(sticker.currentPublisher, publisher1);
        assertEq(sticker.payoutAddress, address(0));

        vm.startPrank(player1);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: newStickerId,
            size: 1
        });
        uint publisherStartingBalance = address(publisher1).balance;
        uint256[] memory objectives;
        (uint256[] memory slapIds, ) = stickerChain.slap{value: slapFee}(newSlaps, objectives);
        assertEq(slapIds.length, 1);

        // test withdrawing publisher payout
        vm.startPrank(publisher1);
        uint payoutBalance = publisherPayoutMethod.balanceOf(publisher1, address(0));
        assertEq(payoutBalance, slapFee / 2);
        address[] memory coins = new address[](1);
        publisherPayoutMethod.withdraw(coins, address(0));
        uint publisherEndingBalance = address(publisher1).balance;
        assertEq(publisherEndingBalance, publisherStartingBalance + (slapFee / 2));
        payoutBalance = publisherPayoutMethod.balanceOf(publisher1, address(0));
        assertEq(payoutBalance, 0);
    }

    // test publishing a sticker with a base token price and getting both protocol and premium fees when it is slapped
    function testPublishPremiumStickerAndReceivePayout() public {
        vm.startPrank(publisher1);
        uint stickerPrice = 0.003 ether;

        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(stickerPrice),
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadataCID1
        });

        uint256 feeAmount = publisherFee + newStickerFee;
        uint256 newStickerId = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);
        StickerDesign memory sticker = stickerDesigns.getStickerDesign(newStickerId);
        assertEq(sticker.metadataCID, metadataCID1);
        assertEq(sticker.price, 0.003 ether);
        assertEq(sticker.originalPublisher, publisher1);
        assertEq(sticker.currentPublisher, publisher1);
        assertEq(sticker.payoutAddress, address(0));

        uint payoutBalance = publisherPayoutMethod.balanceOf(publisher1, address(0));
        assertEq(payoutBalance, 0);

        vm.startPrank(player1);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: newStickerId,
            size: 1
        });
        uint publisherStartingBalance = address(publisher1).balance;
        uint256[] memory objectives;
        (uint256[] memory slapIds, ) = stickerChain.slap{value: slapFee + stickerPrice}(newSlaps, objectives);
        assertEq(slapIds.length, 1);


        // calculate expected payouts
        vm.startPrank(publisher1);
        payoutBalance = publisherPayoutMethod.balanceOf(publisher1, address(0));
        uint expectedPublisherProtocolPayout = slapFee / 2;
        uint expectedAdminFeeOnPremium = (stickerPrice * 500) / 10000;
        uint expectedPublisherPremiumCut = stickerPrice - expectedAdminFeeOnPremium;
        uint expectedFullPublisherPayout = expectedPublisherProtocolPayout + expectedPublisherPremiumCut;
        assertEq(payoutBalance, expectedFullPublisherPayout);

        // test withdrawing publisher payout
        address[] memory coins = new address[](1);
        publisherPayoutMethod.withdraw(coins, address(0));
        uint publisherEndingBalance = address(publisher1).balance;
        assertEq(publisherEndingBalance, publisherStartingBalance + expectedFullPublisherPayout);
        payoutBalance = publisherPayoutMethod.balanceOf(publisher1, address(0));
        assertEq(payoutBalance, 0);
    }


}