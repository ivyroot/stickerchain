// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol";
import "../src/StickerChain.sol";
import "../src/PaymentMethod.sol";
import "../src/StickerObjectives.sol";
import "../src/objectives/NYC.sol";

contract Erc20ObjectiveTest is Test {
    StickerDesigns stickerDesigns;
    PaymentMethod paymentMethod;
    StickerChain stickerChain;
    StickerObjectives stickerObjectives;
    NYC objectiveNYC;
    uint256 objectiveNYCId;
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
        paymentMethod = new PaymentMethod(adminAddress, 0.001 ether);
        stickerDesigns = new StickerDesigns(paymentMethod, adminAddress, 0.002 ether, 0.0005 ether);
        stickerChain = new StickerChain(adminAddress, slapFee, payable(address(stickerDesigns)), payable(address(paymentMethod)));
        stickerObjectives = new StickerObjectives(address(stickerChain), adminAddress, 0.002 ether);
        stickerChain.setStickerObjectivesContract(payable(address(stickerObjectives)));
        objectiveNYC = new NYC(address(stickerChain), adminAddress, "TESTNYC", "$TESTNYC", "https://example.com");
        objectiveNYCId = stickerObjectives.addNewObjective{value: 0.002 ether}(objectiveNYC);

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


    // Test slapping a sticker and accessing via slap id
    function testSlapOneStickerInObjective() public {
        vm.deal(address1, 20 ether);
        vm.startPrank(address1);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId1,
            size: 1
        });
        uint baseSlapFee = stickerChain.slapFeeForSize(1);
        uint calculatedSlapCost = stickerChain.baseTokenCostOfSlaps(newSlaps);
        assertGt(calculatedSlapCost, baseSlapFee);
        uint256[] memory objectives = new uint256[](1);
        objectives[0] = objectiveNYCId;
        stickerChain.slap{value: calculatedSlapCost}(newSlaps, objectives);
        Slap memory slap = stickerChain.getSlap(1);
        assertEq(slap.stickerId, exampleStickerId1);
        assertEq(slap.placeId, placeIdUnionSquare);
        assertEq(slap.player, address1);
        assertEq(slap.slappedAt, block.timestamp);
    }

    // Test slapping a sticker then slapping over it an hour later
    // Ensure the emission rate is correct
    function testSlapOneStickerInObjectiveThenSlapOver() public {
        vm.deal(address1, 20 ether);
        vm.startPrank(address1);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId1,
            size: 1
        });
        uint baseSlapFee = stickerChain.slapFeeForSize(1);
        uint calculatedSlapCost = stickerChain.baseTokenCostOfSlaps(newSlaps);
        assertGt(calculatedSlapCost, baseSlapFee);
        uint256[] memory objectives = new uint256[](1);
        objectives[0] = objectiveNYCId;
        stickerChain.slap{value: calculatedSlapCost}(newSlaps, objectives);
        Slap memory slap = stickerChain.getSlap(1);
        assertEq(slap.stickerId, exampleStickerId1);
        assertEq(slap.placeId, placeIdUnionSquare);
        assertEq(slap.player, address1);
        assertEq(slap.slappedAt, block.timestamp);

        uint currBalance1 = objectiveNYC.balanceOf(address1);
        assertEq(currBalance1, 0);

        // Move time forward an hour
        vm.warp(block.timestamp + 3600);
        vm.roll(block.number + 56);
        uint calculatedSlapCost2 = stickerChain.baseTokenCostOfSlaps(newSlaps);
        assertGt(calculatedSlapCost2, baseSlapFee);
        stickerChain.slap{value: calculatedSlapCost2}(newSlaps, objectives);
        Slap memory slap2 = stickerChain.getSlap(2);
        assertEq(slap2.stickerId, exampleStickerId1);
        assertEq(slap2.placeId, placeIdUnionSquare);
        assertEq(slap2.player, address1);
        assertEq(slap2.slappedAt, block.timestamp);

        uint currBalance2 = objectiveNYC.balanceOf(address1);
        assertEq(currBalance2, 3600000000000000000000);

        // Move time forward one minute
        vm.warp(block.timestamp + 60);
        vm.roll(block.number + 4);
        uint calculatedSlapCost3 = stickerChain.baseTokenCostOfSlaps(newSlaps);
        assertGt(calculatedSlapCost3, baseSlapFee);
        stickerChain.slap{value: calculatedSlapCost3}(newSlaps, objectives);
        Slap memory slap3 = stickerChain.getSlap(3);
        assertEq(slap3.stickerId, exampleStickerId1);
        assertEq(slap3.placeId, placeIdUnionSquare);
        assertEq(slap3.player, address1);
        assertEq(slap3.slappedAt, block.timestamp);

        uint currBalance3 = objectiveNYC.balanceOf(address1);
        assertEq(currBalance3, 3660000000000000000000);

    }


}