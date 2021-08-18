// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract IAssetManager {
  /**
   * @dev Returns an asset if present, otherwise fails.
   */
  function getAsset(uint256 _tokenId) external view virtual returns (address);

  /**
   * @dev Function to mint the NFT for the real esate asset.
   */
  function createAsset(uint256 units, address to) external payable virtual returns (address);
}
