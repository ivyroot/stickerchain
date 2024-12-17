// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol";
import "../src/StickerChain.sol";
import "../src/PaymentMethod.sol";
import "../src/PayoutMethod.sol";
import "../src/renderers/SlapMetaRendererV1.sol";

contract PlayerSlapTest is Test {
    StickerDesigns stickerDesigns;
    PaymentMethod paymentMethod;
    StickerChain stickerChain;
    PayoutMethod publisherPayoutMethod;
    PayoutMethod objectivePayoutMethod;
    SlapMetaRendererV1 slapMetaRenderer;
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
    string imageCID = "QmQD5Pqwi4a55jEZmQoJWnwS2zFhYsZeM1KmbCi6YDpHLV";

    receive() external payable {}
    fallback() external payable {}

    function setUp() public {
        paymentMethod = new PaymentMethod(adminAddress, 0.001 ether);
        stickerDesigns = new StickerDesigns(paymentMethod, adminAddress, 0.002 ether, 0.0005 ether);
        stickerChain = new StickerChain(adminAddress, slapFee, payable(address(stickerDesigns)), payable(address(paymentMethod)));
        publisherPayoutMethod = new PayoutMethod(address(stickerChain), adminAddress);
        objectivePayoutMethod = new PayoutMethod(address(stickerChain), adminAddress);
        stickerChain.setPublisherPayoutMethodContract(payable(address(publisherPayoutMethod)));
        stickerChain.setObjectivePayoutMethodContract(payable(address(objectivePayoutMethod)));
        slapMetaRenderer = new SlapMetaRendererV1(stickerChain, stickerDesigns);
        stickerChain.setMetadataRendererContract(address(slapMetaRenderer));

        vm.deal(address1, 20 ether);
        vm.deal(address2, 20 ether);

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
            metadataCID: metadataCID,
            imageCID: imageCID
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
            metadataCID: metadataCID,
            imageCID: imageCID
        });
        exampleStickerId2 = stickerDesigns.publishStickerDesign{value: newStickerFee}(newStickerDesign2);

    }


    // Test slapping a sticker and reading the token metadata
    function testSlapOneStickerAndGetItsMetadata() public {
        vm.deal(address1, 20 ether);
        vm.warp(1766620801);
        vm.startPrank(address1);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: exampleStickerId1,
            size: 1
        });
        uint baseSlapFee = stickerChain.slapFeeForSize(1);
        uint256[] memory objectives;
        PaymentMethodTotal[] memory calculatedCosts = stickerChain.costOfSlaps(address1, newSlaps, objectives);
        assertEq(calculatedCosts.length, 1);
        assertEq(calculatedCosts[0].paymentMethodId, 0);
        uint calculatedSlapBaseTokenCost = calculatedCosts[0].total;
        assertGt(calculatedSlapBaseTokenCost, baseSlapFee);
        stickerChain.slap{value: calculatedSlapBaseTokenCost}(newSlaps, objectives);
        Slap memory slap = stickerChain.getSlap(1);
        assertEq(slap.stickerId, exampleStickerId1);
        string memory tokenURI = stickerChain.tokenURI(1);
        assertEq(tokenURI, "data:application/json;base64,eyJuYW1lIjogIlNsYXAgIzogMSIsICJzdGlja2VySWQiOiAxLCAicGxhY2VJZCI6IDcxNDc2MTg1OTksICJoZWlnaHQiOiAxLCAic2xhcHBlZEF0IjogMTc2NjYyMDgwMSwgInNpemUiOiAiMSIsICJwbGF5ZXIiOiAiMHg0ODM4YjEwNmZjZTk2NDdiZGYxZTc4NzdiZjczY2U4YjBiYWQ1Zjk3IiwgImltYWdlIjogImlwZnM6Ly9RbVFENVBxd2k0YTU1akVabVFvSldud1MyekZoWXNaZU0xS21iQ2k2WURwSExWIn0=");
    }

}