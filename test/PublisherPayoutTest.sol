// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol";
import "../src/PaymentMethod.sol";
import "../src/PayoutMethod.sol";
import "../src/StickerChain.sol";

contract TestCoin is ERC20, Ownable {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

}

contract PublisherPayoutTest is Test {
    StickerDesigns stickerDesigns;
    PaymentMethod paymentMethod;
    StickerChain stickerChain;
    PayoutMethod publisherPayoutMethod;
    PayoutMethod objectivePayoutMethod;
    TestCoin testCoin;
    uint256 private testCoinPaymentMethodId;
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
    string imageCID = "QmQD5Pqwi4a55jEZmQoJWnwS2zFhYsZeM1KmbCi6YDpHLV";

    receive() external payable {}
    fallback() external payable {}

    // Setup function to deploy the StickerDesigns contract before each test
    function setUp() public {
        vm.deal(adminAddress, 20 ether);
        vm.deal(publisher1, 1 ether);
        vm.deal(player1, 20 ether);
        vm.deal(player2, 20 ether);
        vm.deal(dev1, 1 ether);
        testCoin = new TestCoin("TestCoin", "$TEST");
        testCoin.mint(player1, 1 ether);
        testCoin.mint(player2, 1 ether);
        paymentMethod = new PaymentMethod(adminAddress, 0.001 ether);
        testCoinPaymentMethodId = paymentMethod.addNewCoin(address(testCoin));
        stickerDesigns = new StickerDesigns(paymentMethod, adminAddress, 0.002 ether, 0.0005 ether);
        stickerChain = new StickerChain(adminAddress, slapFee, payable(address(stickerDesigns)), payable(address(paymentMethod)));
        publisherPayoutMethod = new PayoutMethod(address(stickerChain), adminAddress);
        publisherPayoutMethod.setAdminFee(address(0), 500, adminAddress);
        publisherPayoutMethod.setAdminFee(address(testCoin), 500, adminAddress);
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
            metadataCID: metadataCID1,
            imageCID: imageCID
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
        uint publisherStartingBaseTokenBalance = address(publisher1).balance;
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
        assertEq(publisherEndingBalance, publisherStartingBaseTokenBalance + (slapFee / 2));
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
            metadataCID: metadataCID1,
            imageCID: imageCID
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
        uint publisherStartingBaseTokenBalance = address(publisher1).balance;
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
        assertEq(publisherEndingBalance, publisherStartingBaseTokenBalance + expectedFullPublisherPayout);
        payoutBalance = publisherPayoutMethod.balanceOf(publisher1, address(0));
        assertEq(payoutBalance, 0);
    }

    // test publishing a sticker with an ERC20 token price
    // publisher receives protocol fee in base token and premium fee in ERC20 token
    function testPublishPremiumStickerWithERC20PriceAndReceivePayout() public {
        vm.startPrank(publisher1);
        uint stickerPrice = 0.01 ether;

        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(stickerPrice),
            paymentMethodId: testCoinPaymentMethodId,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadataCID1,
            imageCID: imageCID
        });

        uint256 feeAmount = publisherFee + newStickerFee;
        uint256 newStickerId = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);
        StickerDesign memory sticker = stickerDesigns.getStickerDesign(newStickerId);
        assertEq(sticker.metadataCID, metadataCID1);
        assertEq(sticker.paymentMethodId, testCoinPaymentMethodId);
        assertEq(sticker.price, stickerPrice);
        assertEq(sticker.originalPublisher, publisher1);
        assertEq(sticker.currentPublisher, publisher1);
        assertEq(sticker.payoutAddress, address(0));

        // check initial publisher balances
        uint publisherStartingBaseTokenBalance = address(publisher1).balance;
        uint publisherStartingTestCoinBalance = testCoin.balanceOf(publisher1);
        assertEq(publisherStartingTestCoinBalance, 0);
        uint baseTokenPayoutBalance = publisherPayoutMethod.balanceOf(publisher1, address(0));
        assertEq(baseTokenPayoutBalance, 0);
        uint testCoinPayoutBalance = publisherPayoutMethod.balanceOf(publisher1, address(testCoin));
        assertEq(testCoinPayoutBalance, 0);

        // player slaps the sticker
        vm.startPrank(player1);
        // NB: need to approve the payment method contract, not stickerchain
        testCoin.approve(address(paymentMethod), stickerPrice);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: newStickerId,
            size: 1
        });
        uint256[] memory objectives;
        (uint256[] memory slapIds, ) = stickerChain.slap{value: slapFee}(newSlaps, objectives);
        assertEq(slapIds.length, 1);

        // calculate expected payouts
        vm.startPrank(publisher1);
        uint expectedPublisherProtocolPayout = slapFee / 2;
        uint expectedAdminFeeOnPremium = (stickerPrice * 500) / 10000;
        uint expectedPublisherPremiumFee = stickerPrice - expectedAdminFeeOnPremium;

        // check payout balances post slap
        baseTokenPayoutBalance = publisherPayoutMethod.balanceOf(publisher1, address(0));
        assertEq(baseTokenPayoutBalance, expectedPublisherProtocolPayout);
        testCoinPayoutBalance = publisherPayoutMethod.balanceOf(publisher1, address(testCoin));
        assertEq(testCoinPayoutBalance, expectedPublisherPremiumFee);

        // withdraw publisher payout
        address[] memory coins = new address[](2);
        coins[0] = address(0);
        coins[1] = address(testCoin);
        publisherPayoutMethod.withdraw(coins, address(0));

        // base token balance should increase
        uint publisherEndingBalance = address(publisher1).balance;
        assertEq(publisherEndingBalance, publisherStartingBaseTokenBalance + expectedPublisherProtocolPayout);

        // base token payout contract balance should be reset
        baseTokenPayoutBalance = publisherPayoutMethod.balanceOf(publisher1, address(0));
        assertEq(baseTokenPayoutBalance, 0);

        // test coin balance should increase
        uint publisherEndingTestCoinBalance = testCoin.balanceOf(publisher1);
        assertEq(publisherEndingTestCoinBalance, publisherStartingTestCoinBalance + expectedPublisherPremiumFee);

        // test coin payout contract balance should be reset
        testCoinPayoutBalance = publisherPayoutMethod.balanceOf(publisher1, address(testCoin));
        assertEq(testCoinPayoutBalance, 0);
    }

}