pragma solidity ^0.8.24;

struct FreshSlap {
    uint256 slapId;
    uint256 placeId;
    uint256 stickerId;
    uint64 size;
}

interface IStickerObjective {

    function stickerChain() external view returns (address);

    function dev() external view returns (address);

    function objectiveName() external view returns (string memory);

    function url() external view returns (string memory);

    // optional, return empty array if not implemented
    // for example objectives which apply to all places
    function placeList() external view returns (uint[] memory);

    function placeInObjective(uint placeId) external view returns (bool);

    function costOfSlaps(address player, FreshSlap[] calldata slaps) external view
        returns (uint baseCoinCost, address erc20Coin, uint erc20Cost);

    function slapInObjective(address player, FreshSlap[] calldata slaps) external payable
        returns (uint[] memory includedSlapIds);

}