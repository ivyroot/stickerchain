// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol"; // Adjust the path as necessary
import "../src/PaymentMethod.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract StickerDesignsTest is Test {
    StickerDesigns stickerDesigns;
    PaymentMethod paymentMethod;
    uint256 public publisherFee = 0.002 ether;
    uint256 public newStickerFee = 0.0005 ether;
    address adminAddress = address(this);
    address publisher1 = address(0x0B5abAA1548b136661114D0016A9519287B026e2);
    address operator1 = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    string imageCID = "QmQD5Pqwi4a55jEZmQoJWnwS2zFhYsZeM1KmbCi6YDpHLV";


    receive() external payable {}
    fallback() external payable {}

    // Setup function to deploy the StickerDesigns contract before each test
    function setUp() public {
        paymentMethod = new PaymentMethod(adminAddress, 0.001 ether);
        stickerDesigns = new StickerDesigns(paymentMethod, adminAddress, 0.002 ether, 0.0005 ether);
    }

    // Test publishing a sticker design with the fee for a first-time publisher
    function testFirstTimePublisherFee() public {
        bytes memory metadataCID = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';
        uint256 price = 0.1 ether;
        vm.deal(publisher1, 20 ether);
        vm.prank(publisher1);

        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(price),
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadataCID,
            imageCID: imageCID
        });

        uint256 feeAmount = publisherFee + newStickerFee;
        uint256 newStickerId = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);
        StickerDesign memory sticker = stickerDesigns.getStickerDesign(newStickerId);
        assertEq(sticker.metadataCID, metadataCID);
        assertEq(sticker.price, price);
        assertEq(sticker.originalPublisher, publisher1);
        assertEq(sticker.currentPublisher, publisher1);
        assertEq(sticker.payoutAddress, address(0));


    }

    // // Test checking contract reverts if insufficient fee is sent for a first-time publisher
    function testFirstTimePublisherInsufficientFee() public {
        bytes memory metadataCID = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';
        uint256 price = 0.1 ether;
        vm.deal(publisher1, 20 ether);
        vm.prank(publisher1);

        NewStickerDesign memory newStickerDesign = NewStickerDesign({
            payoutAddress: address(0),
            price: uint64(price),
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadataCID,
            imageCID: imageCID
        });

        uint256 incorrectFeeAmount = newStickerFee;
        vm.expectRevert(
            abi.encodeWithSelector(StickerDesigns.InvalidPublishingFee.selector, publisherFee + newStickerFee)
        );
        stickerDesigns.publishStickerDesign{value: incorrectFeeAmount}( newStickerDesign );
    }

    // // Test second sticker creation with the fee for a returning publisher
    function testReturningPublisherFee() public {
        bytes memory metadata1CID = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';
        bytes memory metadata2CID = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54422196e3d342611';
        uint256 price = 0.0 ether;
        address payoutAddress = publisher1;
        vm.deal(publisher1, 20 ether);
        vm.startPrank(publisher1);

        NewStickerDesign memory newStickerDesign1 = NewStickerDesign({
            payoutAddress: payoutAddress,
            price: uint64(price),
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadata1CID,
            imageCID: imageCID
        });
        NewStickerDesign memory newStickerDesign2 = NewStickerDesign({
            payoutAddress: payoutAddress,
            price: uint64(price),
            paymentMethodId: 0,
            limitCount: 0,
            limitTime: 0,
            limitToHolders: address(0),
            metadataCID: metadata2CID,
            imageCID: imageCID
        });

        uint256 newStickerId1 =  stickerDesigns.publishStickerDesign{value: publisherFee + newStickerFee}(newStickerDesign1);
        uint256 newStickerId2 = stickerDesigns.publishStickerDesign{value: newStickerFee}(newStickerDesign2);
        uint256[] memory stickerIds = new uint256[](2);
        stickerIds[0] = newStickerId1;
        stickerIds[1] = newStickerId2;
        StickerDesign[] memory stickers = stickerDesigns.getStickerDesigns(stickerIds);
        assertEq(stickers.length, 2);
        assertEq(stickers[0].metadataCID, metadata1CID);
        assertEq(stickers[0].price, price);
        assertEq(stickers[0].currentPublisher, publisher1);
        assertEq(stickers[0].originalPublisher, publisher1);
        assertEq(stickers[0].payoutAddress, payoutAddress);
        assertEq(stickers[1].metadataCID, metadata2CID);
        assertEq(stickers[1].price, price);
        assertEq(stickers[1].currentPublisher, publisher1);
        assertEq(stickers[1].originalPublisher, publisher1);
        assertEq(stickers[1].payoutAddress, payoutAddress);
    }

    // Test that only admin can set operator
    function testOnlyAdminCanSetOperator() public {
        // Try to set operator as operator1 (should revert)
        vm.prank(operator1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, operator1));
        stickerDesigns.setOperator(operator1);

        // Verify operator is still the initial admin
        assertEq(stickerDesigns.operator(), adminAddress);

        // Admin can set operator
        vm.prank(adminAddress);
        stickerDesigns.setOperator(operator1);
        assertEq(stickerDesigns.operator(), operator1);
    }

    // Test that only operator can set fees
    function testOnlyOperatorCanSetFees() public {
        // Try to set fees as operator1 (should revert since they're not the operator yet)
        vm.prank(operator1);
        vm.expectRevert(StickerDesigns.PublisherPermissionsIssue.selector);
        stickerDesigns.setPublisherReputationFee(0.003 ether);

        vm.prank(operator1);
        vm.expectRevert(StickerDesigns.PublisherPermissionsIssue.selector);
        stickerDesigns.setStickerRegistrationFee(0.001 ether);

        // Verify fees are still the initial values
        assertEq(stickerDesigns.publisherReputationFee(), publisherFee);
        assertEq(stickerDesigns.stickerRegistrationFee(), newStickerFee);

        // Set operator1 as the operator
        vm.prank(adminAddress);
        stickerDesigns.setOperator(operator1);

        // Now operator1 can set fees
        vm.prank(operator1);
        stickerDesigns.setPublisherReputationFee(0.003 ether);
        assertEq(stickerDesigns.publisherReputationFee(), 0.003 ether);

        vm.prank(operator1);
        stickerDesigns.setStickerRegistrationFee(0.001 ether);
        assertEq(stickerDesigns.stickerRegistrationFee(), 0.001 ether);
    }

}
