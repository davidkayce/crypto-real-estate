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
  uint256 public listingId;
  mapping(uint256 => string) private _tokenURIs;

  constructor(
    string memory tokenName,
    string memory symbol,
    address _manager,
    address _owner,
    string memory _tokenURI,
    uint256 _listingId
  ) ERC721(tokenName, symbol) {
    manager = _manager;
    listingId = _listingId;
    mintAsset(_owner, _tokenURI);
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  function mintAsset(address owner, string memory tokenURI) public returns (uint256, address) {
    _tokenIds.increment();
    uint256 tokenId = _tokenIds.current();

    _safeMint(owner, tokenId);
    _setTokenURI(tokenId, tokenURI);
    setApprovalForAll(manager, true);

    return (tokenId, address(this));
  }
}
