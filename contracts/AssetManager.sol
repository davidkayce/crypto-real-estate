// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IAssetManager.sol";
import "./NFT.sol";

import "hardhat/console.sol";

contract AssetManager is ReentrancyGuard, IAssetManager {
  /* The  asset mamager is responsible for setting up the assets, updating value and liquidating assets */
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private _assetIds;
  Counters.Counter private _assetsSold;
  
  /* Events to be picked up by the frontend */
  address payable assetManager;
  address payable issuer;

  uint256 assetSupply;
  uint256 unitPrice;
  uint256 rate;
  
  constructor(address market, address _issuer, uint256 _maxSupply, uint256 _unitPrice, uint256 _rate) {
    assetManager = payable(market);
    issuer = payable(_issuer);
    assetSupply = _maxSupply;
    unitPrice = _unitPrice;
    rate = _rate;
  }
   
  struct Asset {
    uint256 assetId;
    uint256 tokenId;
    uint256 value;
  }

  event AssetCreated (
    uint256 indexed assetId,
    uint256 indexed tokenId,
    uint256 value
  );

  mapping(uint256 => Asset) private idToAsset;
  mapping(address => Asset) private tokenIdToAsset;

  /* Map revenue generated to the assets */
  mapping(Asset => uint256) internal revenues;
  /* Revenue on  asset yet to be distributed */
  uint256 internal accumulated;

  /* Function to fetch  a created asset */ 
  function getAsset(uint _tokenId) external view returns (address) {
    require(tokenIdToAsset[_tokenId], "This asset does not exist");
    return tokenIdToAsset[_tokenId];
  }


  /* Function to mint the NFT for the real esate asset */ 
  function createAsset(uint256 units, address to) public returns (address) {
    uint mintFee = 0.01 ether;
    uint256 totalPrice = SafeMath.mul(units * unitPrice) + mintFee;

    require(assetSupply >= units, "Total supply of assets have been exceeded, you cannot purchase anymore of this asset");
    require(msg.value == totalPrice, "Please pay the asking price with fees");

    payable(issuer).transfer(SafeMath.mul(units * unitPrice));
    payable(assetManager).transfer(mintFee);

    _assetIds.increment();
    uint256 assetId = _assetIds.current();
    address tokenId = new NFT(assetId, assetSupply, unitPrice, rate, msg.sender);

    idToAsset[assetId] = Asset(assetId, tokenId, SafeMath.mul(units * unitPrice));
    tokenIdToAsset[tokenId] = Asset(assetId, tokenId, SafeMath.mul(units * unitPrice));
    emit AssetCreated(assetId, assetAddress);
  }
}