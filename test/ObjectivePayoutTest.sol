// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import "forge-std/Test.sol";
import "../src/StickerDesigns.sol";
import "../src/PaymentMethod.sol";
import "../src/PayoutMethod.sol";
import "../src/StickerChain.sol";
import "../src/IStickerObjective.sol";
import "../src/StickerObjectives.sol";

contract TestCoin is ERC20, Ownable {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

}

contract TestObjective is IStickerObjective, Ownable {
    address immutable public stickerChain;
    address private paymentCoinAddress;
    uint private fee;

    constructor(address _stickerChain, address _paymentCoinAddress, uint _fee) Ownable(msg.sender) {
        stickerChain = _stickerChain;
        paymentCoinAddress = _paymentCoinAddress;
        fee = _fee;
    }

    function feeRecipient() external view returns (address) {
        return owner();
    }

    function owner() public view override(Ownable, IStickerObjective) returns (address) {
        return Ownable.owner();
    }

    function name() external pure returns (string memory) {
        return "TestObjective";
    }

    function url() external pure returns (string memory) {
        return "https://example.com";
    }

    function placeCount() external pure returns (uint) {
        return 0;
    }

    function placeList() external pure returns (uint[] memory) {
        return new uint[](0);
    }

    function costOfSlaps(address, FreshSlap[] calldata slaps) external view
        returns (address, uint, address) {
        return (paymentCoinAddress, fee * slaps.length, owner());
    }

    function slapInObjective(address, FreshSlap[] calldata slaps) external payable
        returns (uint[] memory) {
            uint[] memory slapIds = new uint[](slaps.length);
            for (uint i = 0; i < slaps.length; i++) {
                slapIds[i] = slaps[i].slapId;
            }
        return slapIds;
    }

}


contract ObjectivePayoutTest is Test {
    StickerDesigns stickerDesigns;
    PaymentMethod paymentMethod;
    StickerChain stickerChain;
    StickerObjectives stickerObjectives;
    PayoutMethod publisherPayoutMethod;
    PayoutMethod objectivePayoutMethod;
    TestCoin testCoin;
    TestObjective testObjective;
    uint256 private testObjectiveId;
    uint256 private testCoinPaymentMethodId;
    uint256 public publisherFee = 0.002 ether;
    uint256 public newStickerFee = 0.0005 ether;
    uint256 public slapFee = 0.001 ether;
    uint256 stickerId1;
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
        testCoinPaymentMethodId = paymentMethod.importCoin(address(testCoin));
        stickerDesigns = new StickerDesigns(paymentMethod, adminAddress, 0.002 ether, 0.0005 ether);
        stickerChain = new StickerChain(adminAddress, slapFee, payable(address(stickerDesigns)), payable(address(paymentMethod)));
        stickerObjectives = new StickerObjectives(address(stickerChain), adminAddress, 0.002 ether);
        stickerObjectives.enablePublicCreation();
        stickerChain.setStickerObjectivesContract(payable(address(stickerObjectives)));
        publisherPayoutMethod = new PayoutMethod(address(stickerChain), adminAddress);
        objectivePayoutMethod = new PayoutMethod(address(stickerChain), adminAddress);
        objectivePayoutMethod.setAdminFee(address(0), 500, adminAddress);
        objectivePayoutMethod.setAdminFee(address(testCoin), 500, adminAddress);
        stickerChain.setPublisherPayoutMethodContract(payable(address(publisherPayoutMethod)));
        stickerChain.setObjectivePayoutMethodContract(payable(address(objectivePayoutMethod)));

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
        stickerId1 = stickerDesigns.publishStickerDesign{value: feeAmount}(newStickerDesign);
        assertGt(stickerId1, 0);
    }

    // Test slapping a free objective - no payout
    function testSlapInFreeObjectiveNoDevPayout() public {
        // create and register a new objective
        vm.startPrank(dev1);
        testObjective = new TestObjective(address(stickerChain), address(0), 0);
        testObjectiveId = stickerObjectives.addNewObjective{value: 0.002 ether}(testObjective);
        assertGt(testObjectiveId, 0);
        uint devStartingBaseTokenBalance = address(dev1).balance;
        uint devStartingBaseTokenPayoutBalance = objectivePayoutMethod.balanceOf(dev1, address(0));
        assertEq(devStartingBaseTokenPayoutBalance, 0);

        // slap the objective
        vm.startPrank(player1);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: stickerId1,
            size: 1
        });
        uint256[] memory objectives = new uint256[](1);
        objectives[0] = testObjectiveId;
        (uint256[] memory slapIds, ) = stickerChain.slap{value: slapFee}(newSlaps, objectives);
        assertEq(slapIds.length, 1);

        // test withdrawing publisher payout
        vm.startPrank(dev1);
        uint payoutBalance = objectivePayoutMethod.balanceOf(dev1, address(0));
        assertEq(payoutBalance, 0);
        address[] memory coins = new address[](1);
        objectivePayoutMethod.withdraw(coins, address(0));
        uint devEndingBaseTokenBalance = address(dev1).balance;
        assertEq(devEndingBaseTokenBalance, devStartingBaseTokenBalance);
        payoutBalance = objectivePayoutMethod.balanceOf(dev1, address(0));
        assertEq(payoutBalance, 0);
    }

    function testSlapInObjectiveWithBaseTokenPriceAndDevReceivesPayout() public {
        // create and register a new objective
        vm.startPrank(dev1);
        testObjective = new TestObjective(address(stickerChain), address(0), 0.011 ether);
        testObjectiveId = stickerObjectives.addNewObjective{value: 0.002 ether}(testObjective);
        assertGt(testObjectiveId, 0);
        uint devStartingBaseTokenBalance = address(dev1).balance;
        uint devStartingBaseTokenPayoutBalance = objectivePayoutMethod.balanceOf(dev1, address(0));
        assertEq(devStartingBaseTokenPayoutBalance, 0);

        // slap the objective
        vm.startPrank(player1);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: stickerId1,
            size: 1
        });
        uint256[] memory objectives = new uint256[](1);
        objectives[0] = testObjectiveId;
        (uint256[] memory slapIds, ) = stickerChain.slap{value: slapFee + 0.011 ether}(newSlaps, objectives);
        assertEq(slapIds.length, 1);

        uint expectedAdminObjectiveFee = 0.011 ether * 500 / 10000;
        uint expectedDevPayout = 0.011 ether - expectedAdminObjectiveFee;

        // test withdrawing publisher payout
        vm.startPrank(dev1);
        uint payoutBalance = objectivePayoutMethod.balanceOf(dev1, address(0));
        assertEq(payoutBalance, expectedDevPayout);
        address[] memory coins = new address[](1);
        objectivePayoutMethod.withdraw(coins, address(0));
        uint devEndingBaseTokenBalance = address(dev1).balance;
        assertEq(devEndingBaseTokenBalance, devStartingBaseTokenBalance + expectedDevPayout);
        payoutBalance = objectivePayoutMethod.balanceOf(dev1, address(0));
        assertEq(payoutBalance, 0);
    }

    function testSlapInObjectiveWithUnregisteredERC20() public {
        // dev setup
        vm.startPrank(dev1);
        // make a new test coin not in payment methods contract
        TestCoin testCoin2 = new TestCoin("TestCoin2", "$TEST2");
        testObjective = new TestObjective(address(stickerChain), address(testCoin2), 0.011 ether);
        testObjectiveId = stickerObjectives.addNewObjective{value: 0.002 ether}(testObjective);
        assertGt(testObjectiveId, 0);

        // player tests
        vm.startPrank(player1);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: stickerId1,
            size: 1
        });
        uint256[] memory objectives = new uint256[](1);
        objectives[0] = testObjectiveId;

        // Check costs before slapping
        PaymentMethodTotal[] memory costs = stickerChain.costOfSlaps(player1, newSlaps, objectives);
        assertEq(costs.length, 1); // Should have base token only since ERC20 is not registered
        assertEq(costs[0].paymentMethodId, 0); // Base token
        assertEq(costs[0].total, slapFee); // Only slap fee in base token

        // Execute the slap
        (uint256[] memory slapIds, ) = stickerChain.slap{value: slapFee + 0.011 ether}(newSlaps, objectives);
        assertEq(slapIds.length, 1);

    }

    function testSlapInObjectiveWithERC20PriceAndDevReceivesPayout() public {
        // create and register a new objective
        vm.startPrank(dev1);
        testObjective = new TestObjective(address(stickerChain), address(testCoin), 0.011 ether);
        testObjectiveId = stickerObjectives.addNewObjective{value: 0.002 ether}(testObjective);
        assertGt(testObjectiveId, 0);
        uint devStartingBaseTokenBalance = address(dev1).balance;
        uint devStartingBaseTokenPayoutBalance = objectivePayoutMethod.balanceOf(dev1, address(0));
        assertEq(devStartingBaseTokenPayoutBalance, 0);
        uint devStartingTestCoinBalance = testCoin.balanceOf(dev1);
        assertEq(devStartingTestCoinBalance, 0);
        assertEq(testObjective.feeRecipient(), dev1);

        // Prepare slap data
        vm.startPrank(player1);
        testCoin.approve(address(paymentMethod), 100 ether);
        NewSlap[] memory newSlaps = new NewSlap[](1);
        newSlaps[0] = NewSlap({
            placeId: placeIdUnionSquare,
            stickerId: stickerId1,
            size: 1
        });
        uint256[] memory objectives = new uint256[](1);
        objectives[0] = testObjectiveId;

        // Check costs before slapping
        PaymentMethodTotal[] memory costs = stickerChain.costOfSlaps(player1, newSlaps, objectives);
        assertEq(costs.length, 2); // Should have base token (for slap fee) and ERC20 (for objective fee)
        assertEq(costs[0].paymentMethodId, 0); // Base token
        assertEq(costs[0].total, slapFee); // Only slap fee in base token
        assertEq(costs[1].paymentMethodId, 1); // Test coin
        assertEq(costs[1].total, 0.011 ether); // Objective fee in test coin

        // Execute the slap
        (uint256[] memory slapIds, ) = stickerChain.slap{value: slapFee + 0.011 ether}(newSlaps, objectives);
        assertEq(slapIds.length, 1);

        uint expectedAdminObjectiveFee = 0.011 ether * 500 / 10000;
        uint expectedDevPayout = 0.011 ether - expectedAdminObjectiveFee;

        // check balances have accrued
        vm.startPrank(dev1);
        uint payoutBalanceBaseToken = objectivePayoutMethod.balanceOf(dev1, address(0));
        assertEq(payoutBalanceBaseToken, 0);
        uint payoutBalanceTestCoin = objectivePayoutMethod.balanceOf(dev1, address(testCoin));
        assertEq(payoutBalanceTestCoin, expectedDevPayout);

        // withdraw the payout
        address[] memory coins = new address[](2);
        coins[0] = address(testCoin);
        coins[1] = address(0);
        objectivePayoutMethod.withdraw(coins, address(0));
        uint devEndingBaseTokenBalance = address(dev1).balance;
        assertEq(devEndingBaseTokenBalance, devStartingBaseTokenBalance);
        payoutBalanceBaseToken = objectivePayoutMethod.balanceOf(dev1, address(0));
        assertEq(payoutBalanceBaseToken, 0);

        // verify the test coin balance and payout balance
        uint devEndingTestCoinBalance = testCoin.balanceOf(dev1);
        assertEq(devEndingTestCoinBalance, expectedDevPayout);
        payoutBalanceTestCoin = objectivePayoutMethod.balanceOf(dev1, address(testCoin));
        assertEq(payoutBalanceTestCoin, 0);
    }
}