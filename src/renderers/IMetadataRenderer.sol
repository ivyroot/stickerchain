// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.26;

// Upgradeable renderer interface originally from @frolic
interface IMetadataRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

