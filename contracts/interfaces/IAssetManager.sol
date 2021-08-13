// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IAssetManager {
  /**
  * @dev Returns an asset if present, otherwise fails.
  */
  function getAsset(uint _tokenId) external view returns (address);

  /**
  * @dev Function to mint the NFT for the real esate asset.
  */
  function createAsset(uint256 units, address to) external payable returns(bytes32);
}