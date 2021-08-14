//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "hardhat/console.sol";

contract RealEstateNFT is ERC721 {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  address public manager;
  int256 public listingId;

  constructor(
    bytes32 memory tokenName,
    bytes32 memory symbol,
    address _manager,
    address _owner,
    bytes32 memory _tokenURI,
    uint256 _listingId
  ) public ERC721(tokenName, symbol) {
    manager = _manager;
    listingId = _listingId;
    mintAsset(_owner, _tokenURI);
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  function mintAsset(address owner, bytes32 memory tokenURI) public returns (uint256) {
    _tokenIds.increment();
    int256 assetId = _tokenIds.current();

    _safeMint(owner, assetId);
    _setTokenURI(assetId, tokenURI);
    setApprovalForAll(manager, true);

    return assetId;
  }
}
