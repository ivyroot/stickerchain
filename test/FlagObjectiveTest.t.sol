// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol";
import "../src/StickerChain.sol";
import "../src/PaymentMethod.sol";
import "../src/PayoutMethod.sol";
import "../src/StickerObjectives.sol";
import "../src/objectives/FlagObjective.sol";

contract FlagObjectiveTest is Test {
    StickerDesigns stickerDesigns;
    PaymentMethod paymentMethod;
    StickerChain stickerChain;
    PayoutMethod publisherPayoutMethod;
    PayoutMethod objectivePayoutMethod;
    StickerObjectives stickerObjectives;
    FlagObjective objectiveFlag;
    uint256 objectiveFlagId;
    uint256 public publisherFee = 0.002 ether;
    uint256 public newStickerFee = 0.0005 ether;
    uint256 public slapFee = 0.001 ether;
    uint256 private exampleStickerId1;
    uint64 private exampleStickerPrice = uint64(0.1 ether);
    address adminAddress = address(this);
    address address1 = address(0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97);
    string imageCID = "QmQD5Pqwi4a55jEZmQoJWnwS2zFhYsZeM1KmbCi6YDpHLV";

    receive() external payable {}
    fallback() external payable {}

    function setUp() public {
        paymentMethod = new PaymentMethod(adminAddress, 0.001 ether);
        stickerDesigns = new StickerDesigns(paymentMethod, adminAddress, 0.002 ether, 0.0005 ether);
        stickerChain = new StickerChain(adminAddress, slapFee, payable(address(stickerDesigns)), payable(address(paymentMethod)));
        stickerObjectives = new StickerObjectives(address(stickerChain), adminAddress, 0.002 ether);
        stickerChain.setStickerObjectivesContract(payable(address(stickerObjectives)));
        publisherPayoutMethod = new PayoutMethod(address(stickerChain), adminAddress);
        objectivePayoutMethod = new PayoutMethod(address(stickerChain), adminAddress);
        stickerChain.setPublisherPayoutMethodContract(payable(address(publisherPayoutMethod)));
        stickerChain.setObjectivePayoutMethodContract(payable(address(objectivePayoutMethod)));

        // Create flag objective and register it
        objectiveFlag = new FlagObjective(address(stickerChain), adminAddress, "https://example.com");
        objectiveFlagId = stickerObjectives.addNewObjective{value: 0.002 ether}(objectiveFlag);

        // Create example sticker
        bytes memory metadataCID = hex'122080b67c703b2894ce2b368adf632cc1f169cb41c25e4334c54474196e3d342627';
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
    }

    function testObjectiveMeta() public view {
        ObjectiveMeta memory meta = stickerObjectives.getObjectiveMeta(objectiveFlagId);
        assertEq(meta.owner, adminAddress);
        assertEq(meta.feeRecipient, adminAddress);
        assertEq(meta.name, "Capture the Flag");
        assertEq(meta.url, "https://example.com");
        assertEq(meta.placeCount, 0); // Flag objective accepts all places
        assertEq(meta.placeList.length, 0);
    }

    function testPlantFlag() public {
        vm.deal(address1, 20 ether);
        vm.startPrank(address1);

        // Create a new slap at a location
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: 7147618599, // Example place ID
            stickerId: exampleStickerId1,
            size: 1
        });
        uint256[] memory objectives = new uint256[](1);
        objectives[0] = objectiveFlagId;

        PaymentMethodTotal[] memory calculatedCosts = stickerChain.costOfSlaps(address1, newSlaps, objectives);
        uint256 calculatedSlapBaseTokenCost = calculatedCosts[0].total;

        // Plant the flag
        stickerChain.slap{value: calculatedSlapBaseTokenCost}(newSlaps, objectives);

        // Verify flag was planted
        assertEq(objectiveFlag.flaggedPlaceId(), 7147618599);
        assertEq(objectiveFlag.pointsForPlayer(address1), 100000); // Base points for first flag
    }

    function testCannotPlantFlagInPreviousSpot() public {
        vm.deal(address1, 20 ether);
        vm.startPrank(address1);

        // First flag placement
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: 6003970435, // First location
            stickerId: exampleStickerId1,
            size: 1
        });
        uint256[] memory objectives = new uint256[](1);
        objectives[0] = objectiveFlagId;

        PaymentMethodTotal[] memory calculatedCosts = stickerChain.costOfSlaps(address1, newSlaps, objectives);
        uint256 calculatedSlapBaseTokenCost = calculatedCosts[0].total;

        // Plant first flag
        stickerChain.slap{value: calculatedSlapBaseTokenCost}(newSlaps, objectives);
        uint256 initialPoints = objectiveFlag.pointsForPlayer(address1);
        assertEq(objectiveFlag.flaggedPlaceId(), 6003970435);
        assertEq(initialPoints, 100000); // Base points for first flag

        // Second flag placement at different location
        newSlaps[0].placeId = 6608169091; // Second location (e.g., Hollywood Sign)
        calculatedCosts = stickerChain.costOfSlaps(address1, newSlaps, objectives);
        calculatedSlapBaseTokenCost = calculatedCosts[0].total;

        // Plant second flag
        stickerChain.slap{value: calculatedSlapBaseTokenCost}(newSlaps, objectives);
        uint256 secondPoints = objectiveFlag.pointsForPlayer(address1);
        assertEq(objectiveFlag.flaggedPlaceId(), 6608169091);
        assertGt(secondPoints, initialPoints); // Should have earned more points

        // Check that the points are calculated correctly
        assertEq(objectiveFlag.pointsForPlayer(address1), 160000);

        // Try to plant flag back in first location
        newSlaps[0].placeId = 6003970435; // Back to first location
        calculatedCosts = stickerChain.costOfSlaps(address1, newSlaps, objectives);
        calculatedSlapBaseTokenCost = calculatedCosts[0].total;

        // Attempt to plant flag in previous location
        stickerChain.slap{value: calculatedSlapBaseTokenCost}(newSlaps, objectives);

        // Verify:
        // 1. Flag location hasn't changed
        assertEq(objectiveFlag.flaggedPlaceId(), 6608169091);
        // 2. Points haven't increased
        assertEq(objectiveFlag.pointsForPlayer(address1), secondPoints);
        // 3. The slap itself was successful (can verify by checking if it exists in StickerChain)
        Slap memory slap = stickerChain.getSlap(3);
        assertEq(slap.placeId, 6003970435);
        assertEq(slap.player, address1);
    }
}
