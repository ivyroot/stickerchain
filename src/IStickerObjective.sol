pragma solidity ^0.8.24;

struct FreshSlap {
    uint256 slapId;
    uint256 placeId;
    uint256 stickerId;
    uint64 size;
}

interface IStickerObjective {

    function stickerChain() external view returns (address);

    function owner() external view returns (address);

    function name() external view returns (string memory);

    function url() external view returns (string memory);

    // 0 == ¯\_(ツ)_/¯
    function placeCount() external view returns (uint);

    // [] == ¯\_(ツ)_/¯
    function placeList() external view returns (uint[] memory);

    function costOfSlaps(address player, FreshSlap[] calldata slaps) external view
        returns (uint paymentMethodId, uint cost, address recipient);

    function slapInObjective(address player, FreshSlap[] calldata slaps) external payable
        returns (uint[] memory includedSlapIds);

}