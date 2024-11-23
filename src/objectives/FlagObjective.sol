// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "block-places/BlockPlaces.sol";
import "../IStickerObjective.sol";

contract FlagObjective is IStickerObjective, Ownable {

    // standard objective values
    address immutable public stickerChain;
    string public url;
    address public feeRecipient;
    address public paymentCoin;
    uint256 public slapFee;

    // flag state
    uint256 public flaggedPlaceId;
    mapping(uint256 => uint256) public flaggedPlaces;

    // player scores
    mapping(address => uint256) private playerScores;

    constructor(address _stickerChain, address _initialAdmin, string memory _url)
        Ownable(_initialAdmin)
    {
        stickerChain = _stickerChain;
        feeRecipient = _initialAdmin;
        url = _url;
    }

    function owner() public view override(Ownable, IStickerObjective) returns (address) {
        return Ownable.owner();
    }

    function name() external pure returns (string memory) {
        return "Capture the Flag";
    }

    function setUrl(string memory _url) external onlyOwner {
        url = _url;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function setSlapFee(address _paymentCoinAddress, uint256 _slapFee) external onlyOwner {
        paymentCoin = _paymentCoinAddress;
        slapFee = _slapFee;
    }

    function placeCount() external pure returns (uint256) {
        return 0; // Indicates all places are valid
    }

    function placeList() external pure returns (uint256[] memory) {
        return new uint256[](0); // Indicates all places are valid
    }

    function costOfSlaps(address, FreshSlap[] calldata)
        external
        view
        returns (address, uint256, address)
    {
        return (paymentCoin, slapFee, feeRecipient);
    }

    function slapInObjective(address player, FreshSlap[] calldata slaps)
        external
        payable
        returns (uint256[] memory)
    {
        if (msg.sender != stickerChain) {
            revert InvalidCaller();
        }
        uint256[] memory includedSlapIds = new uint256[](1);

        // Find first valid flag placement
        for (uint i = 0; i < slaps.length; i++) {
            if (flaggedPlaces[slaps[i].placeId] == 0) {

                // Calculate points
                uint256 points = calculatePoints(flaggedPlaceId, slaps[i].placeId);
                playerScores[player] += points;

                // Plant flag
                flaggedPlaces[slaps[i].placeId] = slaps[i].slapId;
                flaggedPlaceId = slaps[i].placeId;

                // Store the single valid slap ID
                includedSlapIds[0] = slaps[i].slapId;
                break;
            }
        }

        return includedSlapIds;
    }

    function calculatePoints(uint256 lastPlaceId, uint256 newPlaceId)
        internal
        pure
        returns (uint256)
    {
        (, uint lng1, uint lngDecimal1, uint lat1, uint latDecimal1) = BlockPlaces.blockPlaceFromPlaceId(lastPlaceId);
        (, uint lng2, uint lngDecimal2, uint lat2, uint latDecimal2) = BlockPlaces.blockPlaceFromPlaceId(newPlaceId);
        uint256 degreeDistance = (lng1 > lng2 ? lng1 - lng2 : lng2 - lng1) + (lat1 > lat2 ? lat1 - lat2 : lat2 - lat1);
        if (degreeDistance == 0) {
            uint256 decimalDistance = (lngDecimal1 > lngDecimal2 ? lngDecimal1 - lngDecimal2 : lngDecimal2 - lngDecimal1) +
                                (latDecimal1 > latDecimal2 ? latDecimal1 - latDecimal2 : latDecimal2 - latDecimal1);
            return decimalDistance % 2 == 0 ? 20 : 15;
        }
        uint256 basePoints = degreeDistance > 25 ? 100 : 10;
        uint256 ringPosition = degreeDistance % 4;
        return basePoints + (ringPosition * 25);
    }

    function pointsForPlayer(address player) external view returns (uint256) {
        return playerScores[player];
    }

    function pointsForPlayers(address[] calldata players)
        external
        view
        returns (uint256[] memory scores)
    {
        scores = new uint256[](players.length);
        for (uint256 i = 0; i < players.length; i++) {
            scores[i] = playerScores[players[i]];
        }
        return scores;
    }
}
