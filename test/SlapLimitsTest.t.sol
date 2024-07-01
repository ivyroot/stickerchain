// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol";
import "../src/PaymentMethod.sol";
import "../src/StickerChain.sol";


contract BalanceCheckerDeny {
    function balanceOf(address addr) public pure returns (uint256) {
        assert(addr != address(0));
        return 0;
    }
}

contract BalanceCheckerAllow {
    function balanceOf(address addr) public pure returns (uint256) {
        assert(addr != address(0));
        return 1;
    }
}

contract BalanceCheckerWriteOnCheck {
    uint256 public checkCount = 0;
    function balanceOf(address addr) public returns (uint256) {
        assert(addr != address(0));
        checkCount++;
        return checkCount;
    }
}

contract SlapLimitsTest is Test {
    StickerDesigns stickerDesigns;
    PaymentMethod paymentMethod;
    StickerChain stickerChain;
    uint256 public publisherFee = 0.002 ether;
    uint256 public newStickerFee = 0.0005 ether;
    uint256 public slapFee = 0.001 ether;
    uint256 private placeIdUnionSquare = 7147618599;
    uint256 private placeIdHollywoodSign = 4126216247;
    address adminAddress = address(this);
    address publisher = address(0x0B5abAA1548b136661114D0016A9519287B026e2);
    address address1 = address(0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97);
    address address2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address address3 = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    bytes metadataCID1 = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';

    receive() external payable {}
    fallback() external payable {}

    function setUp() public {
        vm.deal(publisher, 20 ether);
        vm.deal(adminAddress, 20 ether);
        vm.deal(address1, 20 ether);
        vm.deal(address2, 20 ether);
        vm.deal(address3, 20 ether);
        stickerDesigns = new StickerDesigns(adminAddress, 0.002 ether, 0.0005 ether);
        paymentMethod = new PaymentMethod(adminAddress, 0.001 ether);
        stickerChain = new StickerChain(adminAddress, slapFee, payable(address(stickerDesigns)), payable(address(paymentMethod)));
    }

    // validate cannot slap sticker limited to holders if balance is zero in holder contract
    function testLimitToHoldersCannotSlapIfNotHolder() public {
        BalanceCheckerDeny balanceCheckerDeny = new BalanceCheckerDeny();

        NewStickerDesign memory newStickerDesignA = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(0),
            paymentMethodId: 0,
            limitCount: 8,
            limitTime: 0,
            limitToHolders: address(balanceCheckerDeny),
            metadataCID: metadataCID1
        });

        // publish sticker gated by balance check which always returns 0
        vm.startPrank(publisher);
        uint256 feeAmount = stickerDesigns.costToPublish(publisher);
        uint stickerId1;
        stickerId1 = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesignA);

        // try to slap sticker with balance check that always returns 0
        vm.startPrank(address1);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: stickerId1,
            size: 1
        });
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.SlapNotAllowed.selector, stickerId1, 103)
        );
        stickerChain.slap{value: slapFee}(newSlaps);
    }

    // validate can slap sticker limited to holders if balance is non-zero in holder contract
    function testLimitToHoldersCanSlapIfHolder() public {
        BalanceCheckerAllow balanceCheckerAllow = new BalanceCheckerAllow();

        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(0),
            paymentMethodId: 0,
            limitCount: 8,
            limitTime: 0,
            limitToHolders: address(balanceCheckerAllow),
            metadataCID: metadataCID1
        });

        // publish sticker gated by balance check which always returns 1
        vm.prank(publisher);
        uint256 feeAmount = publisherFee + newStickerFee;
        uint stickerId1;
        stickerId1 = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);

        // slap sticker with balance check that always returns 1
        vm.startPrank(address1);
        uint nextSlapId = stickerChain.nextSlapId();
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: stickerId1,
            size: 1
        });
        stickerChain.slap{value: slapFee}(newSlaps);

        Slap memory slap = stickerChain.getSlap(nextSlapId);
        assertEq(slap.stickerId, stickerId1);
        assertEq(slap.placeId, placeIdUnionSquare);
        assertEq(slap.size, 1);
        assertEq(slap.slappedAt, block.timestamp);
        assertEq(slap.player, address1);
    }

    // validate slap throws if balance check contract writes on check
    function testLimitToHoldersThrowsIfExternalContractChangesState() public {
        BalanceCheckerWriteOnCheck balanceCheckerWriteOnCheck = new BalanceCheckerWriteOnCheck();

        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(0),
            paymentMethodId: 0,
            limitCount: 8,
            limitTime: 0,
            limitToHolders: address(balanceCheckerWriteOnCheck),
            metadataCID: metadataCID1
        });

        // publish sticker gated by balance check which writes on check
        vm.prank(publisher);
        uint256 feeAmount = publisherFee + newStickerFee;
        uint stickerId1;
        stickerId1 = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);

        // try to slap sticker with balance check that writes on check
        vm.startPrank(address1);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: stickerId1,
            size: 1
        });
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.SlapNotAllowed.selector, stickerId1, 411)
        );
        stickerChain.slap{value: slapFee}(newSlaps);
    }

    // validate design with limit of 3 can only be slapped 3 times
    function testLimitCount() public {
        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(0),
            paymentMethodId: 0,
            limitCount: 3,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadataCID1
        });

        // publish sticker with limit of 3
        vm.prank(publisher);
        uint256 feeAmount = publisherFee + newStickerFee;
        uint stickerId1;
        stickerId1 = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);

        // slap sticker 3 times
        vm.startPrank(address1);
        NewSlap[] memory newSlap = new NewSlap[](1);
        newSlap[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: stickerId1,
            size: 1
        });
        stickerChain.nextSlapId();
        stickerChain.slap{value: slapFee}(newSlap);
        stickerChain.nextSlapId();
        stickerChain.slap{value: slapFee}(newSlap);

        vm.startPrank(address2);
        stickerChain.nextSlapId();
        stickerChain.slap{value: slapFee}(newSlap);
        // try to slap sticker a 4th time
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.SlapNotAllowed.selector, stickerId1, 102)
        );
        stickerChain.slap{value: slapFee}(newSlap);
    }

    // validate sticker cannot be slapped after published caps it
    function testCappingSticker() public {
        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(0),
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadataCID1
        });

        // publish sticker with no limit
        vm.prank(publisher);
        uint256 feeAmount = publisherFee + newStickerFee;
        uint stickerId1;
        stickerId1 = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);

        // slap sticker
        NewSlap[] memory newSlap = new NewSlap[](1);
        newSlap[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: stickerId1,
            size: 1
        });
        vm.startPrank(address1);
        stickerChain.slap{value: slapFee}(newSlap);

        // cap sticker
        vm.startPrank(publisher);
        stickerDesigns.capSticker(stickerId1);

        // advance by 1 second and 1 block
        skip(1);
        vm.roll(block.number + 1);

        // try to slap sticker again
        vm.startPrank(address1);
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.SlapNotAllowed.selector, stickerId1, 101)
        );
        stickerChain.slap{value: slapFee}(newSlap);
    }


    // validate sticker cannot be slapped after time limit is reached
    function testStickerLimitTime() public {
        uint currentTime = block.timestamp;
        uint64 expirationTime = uint64(currentTime + 60);
        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(0),
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: expirationTime,
            limitToHolders: address(0),
            metadataCID: metadataCID1
        });

        // publish sticker with no limit
        vm.prank(publisher);
        uint256 feeAmount = publisherFee + newStickerFee;
        uint stickerId1;
        stickerId1 = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);

        // slap sticker
        vm.startPrank(address1);
        NewSlap[] memory newSlap = new NewSlap[](1);
        newSlap[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: stickerId1,
            size: 1
        });
        stickerChain.slap{value: slapFee}(newSlap);

        // advance by 2 minutes and 8 blocks
        skip(120);
        vm.roll(block.number + 8);

        // try to slap sticker again
        vm.startPrank(address1);
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.SlapNotAllowed.selector, stickerId1, 101)
        );
        stickerChain.slap{value: slapFee}(newSlap);
    }


}
