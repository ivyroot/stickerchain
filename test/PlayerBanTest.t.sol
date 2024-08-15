// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol";
import "../src/StickerChain.sol";
import "../src/PaymentMethod.sol";
import "../src/PayoutMethod.sol";

contract PlayerBanTest is Test {
    StickerDesigns stickerDesigns;
    PaymentMethod paymentMethod;
    StickerChain stickerChain;
    PayoutMethod publisherPayoutMethod;
    PayoutMethod objectivePayoutMethod;
    uint256 public publisherFee = 0.002 ether;
    uint256 public newStickerFee = 0.0005 ether;
    uint256 public slapFee = 0.001 ether;
    uint256 private exampleStickerId1;
    uint64 private exampleStickerPrice = uint64(0.1 ether);
    uint256 private exampleStickerId2;
    uint256 private placeIdUnionSquare = 7147618599;
    uint256 private placeIdHollywoodSign = 4126216247;
    address adminAddress = address(this);
    address address1 = address(0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97);
    address address2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address address3 = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    receive() external payable {}
    fallback() external payable {}

    function setUp() public {
        vm.deal(address1, 20 ether);
        vm.deal(address2, 20 ether);
        vm.deal(address3, 20 ether);
        paymentMethod = new PaymentMethod(adminAddress, 0.001 ether);
        stickerDesigns = new StickerDesigns(paymentMethod, adminAddress, 0.002 ether, 0.0005 ether);
        stickerChain = new StickerChain(adminAddress, slapFee, payable(address(stickerDesigns)), payable(address(paymentMethod)));
        publisherPayoutMethod = new PayoutMethod(address(stickerChain), adminAddress);
        objectivePayoutMethod = new PayoutMethod(address(stickerChain), adminAddress);
        stickerChain.setPublisherPayoutMethodContract(payable(address(publisherPayoutMethod)));
        stickerChain.setObjectivePayoutMethodContract(payable(address(objectivePayoutMethod)));

        bytes memory metadataCID = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';
        address publisher = adminAddress;
        vm.deal(publisher, 20 ether);
        vm.prank(publisher);

        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: exampleStickerPrice,
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
            price: uint64(0 ether),
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadataCID
        });
        exampleStickerId2 = stickerDesigns.publishStickerDesign{value: newStickerFee}(newStickerDesign2);

    }

    function testBannedPlayerCannotSlap() public {
        address[] memory banPlayers = new address[](1);
        banPlayers[0] = address1;
        stickerChain.banPlayers(banPlayers, false);
        vm.startPrank(address1);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId2,
            size: 1
        });
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.PlayerIsBanned.selector)
        );
        uint256[] memory objectives;
        stickerChain.slap{value: slapFee}(newSlaps, objectives);
    }

    function testRandomAccountCannotBanPlayers() public {
        vm.startPrank(address3);
        address[] memory banPlayers = new address[](1);
        banPlayers[0] = address2;
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.PermissionDenied.selector)
        );
        stickerChain.banPlayers(banPlayers, false);
    }

    function testBanOperatorAccountCanBanPlayers() public {
        stickerChain.setBanOperator(address3);
        vm.startPrank(address3);
        address[] memory banPlayers = new address[](1);
        banPlayers[0] = address2;
        stickerChain.banPlayers(banPlayers, false);
        bool isBanned = stickerChain.isBanned(address2);
        assertEq(isBanned, true);
        vm.startPrank(address2);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId2,
            size: 1
        });
        uint256[] memory objectives;
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.PlayerIsBanned.selector)
        );
        stickerChain.slap{value: slapFee}(newSlaps, objectives);
    }

    function testAdminCannotChangeBanOperatorAfterItsLocked() public {
        stickerChain.setBanOperator(address3);
        assertEq(stickerChain.banOperator(), address3);
        stickerChain.lockBanOperator();
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.FeatureIsLocked.selector)
        );
        stickerChain.setBanOperator(address2);
    }


}