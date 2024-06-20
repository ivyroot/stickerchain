// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol";
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


    function setUp() public {
        stickerDesigns = new StickerDesigns(msg.sender, 0.002 ether, 0.0005 ether);
        stickerChain = new StickerChain(slapFee, payable(address(stickerDesigns)));
    }

    // validate cannot slap sticker limited to holders if balance is zero in holder contract
    function testLimitToHoldersCannotSlapIfNotHolder() public {
        BalanceCheckerDeny balanceCheckerDeny = new BalanceCheckerDeny();

        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(0),
            limitCount: 8,
            limitTime: 0,
            limitToHolders: address(balanceCheckerDeny),
            metadataCID: metadataCID1
        });

        // publish sticker gated by balance check which always returns 0
        vm.deal(publisher, 20 ether);
        vm.prank(publisher);
        uint256 feeAmount = publisherFee + newStickerFee;
        uint stickerId1;
        stickerId1 = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);

        // try to slap sticker with balance check that always returns 0
        vm.deal(address1, 20 ether);
        vm.startPrank(address1);
        vm.expectRevert(
            abi.encodeWithSelector(StickerChain.SlapNotAllowed.selector, stickerId1)
        );
        stickerChain.slap{value: slapFee}(placeIdUnionSquare, stickerId1, 1);
    }



}
