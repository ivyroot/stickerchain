pragma solidity ^0.8.24;

struct FreshSlap {
    uint256 slapId;
    uint256 placeId;
    uint256 stickerId;
    uint64 size;
}

interface IStickerObjective {

    function stickerChain() external view returns (address);

    function dev(uint _objectiveId) external view returns (address);

    function costOfSlaps(address player, FreshSlap[] calldata slaps) external view
        returns (uint baseCoinCost, address erc20Coin, uint erc20Cost);

    function slapInObjective(address player, FreshSlap[] calldata slaps) external payable
        returns (uint[] memory includedSlapIds);

}