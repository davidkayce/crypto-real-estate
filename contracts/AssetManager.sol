// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IAssetManager.sol";
import "./NFT.sol";

import "hardhat/console.sol";

contract AssetManager is ReentrancyGuard, IAssetManager, Ownable {
  /* The  asset mamager is responsible for setting up the assets, updating value and liquidating assets */
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private _assetIds;
  
  /* Events to be picked up by the frontend */
  address payable market;
  address payable issuer;

  int public assetSupply;
  int public unitPrice;
  int public unitsSold;
  int8 public rate;
  
  constructor(address _market, address _issuer, uint256 _maxSupply, uint256 _unitPrice, uint256 _rate, bytes32 memory tokenURI) {
    market = payable(_market);
    issuer = payable(_issuer);
    assetSupply = _maxSupply;
    unitPrice = _unitPrice;
    rate = _rate;
  }
   
  struct Asset {
    int assetId;
    int tokenId;
    int value;
  }

  event AssetCreated (
    int indexed assetId,
    int indexed tokenId,
    int value
  );

  event AssetValueUpdated (Asset asset);

  mapping(int => Asset) private idToAsset;
  mapping(address => Asset) private tokenIdToAsset;
  mapping(Asset => int) private depositTimeStamp;
  mapping(Asset => int) private interestPaid;

  /* Revenue on  asset yet to be distributed */
  int internal accumulated = 0;

  /* Function to fetch  a created asset */ 
  function getAsset(int _tokenId) public view returns (Asset) {
    require(tokenIdToAsset[_tokenId], "This asset does not exist");
    return tokenIdToAsset[_tokenId];
  }

  function isStakeholder(int id) public view returns (bool, Asset) {
    if (idToAsset[id]) return (true, idToAsset[id]);
    return (false, Asset(0,0,0));
  }

  function isSoldOut() public view returns (bool) {
    return (unitsSold >= assetSupply);
  }

  /* Function to mint the NFT for the real esate asset */ 
  function createAsset(uint256 units, address to) public returns (address) {
    int8 mintFee = 0.01 ether;
    int totalPrice = SafeMath.mul(units, unitPrice) + mintFee;

    require(assetSupply >= SafeMath.add(units, unitsSold), "Total supply of assets have been exceeded, you cannot purchase anymore of this asset");
    require(msg.value == totalPrice, "Please pay the asking price with fees");

    payable(issuer).transfer(SafeMath.mul(units, unitPrice));
    payable(market).transfer(mintFee);

    _assetIds.increment();
    unitsSold += units;
    
    int assetId = _assetIds.current();
    int tokenId = new RealEstateNFT(assetId, assetSupply, unitPrice, rate, msg.sender);

    idToAsset[assetId] = Asset(assetId, tokenId, SafeMath.mul(units, unitPrice));
    tokenIdToAsset[tokenId] = Asset(assetId, tokenId, SafeMath.mul(units, unitPrice));
    depositTimeStamp[idToAsset[assetId]] = block.timestamp;

    emit AssetCreated(assetId, assetAddress);
  }

  /* This code is run anytime money is sent to this address */
  receive() external payable  {
    require(msg.value > 0, "Non-zero revenue please");
    accumulated += msg.value;
    payable(market).transfer(msg.value);
  }

  // Integrate chainlink API here to automatically 
  // distribute revenue to the assets

  /* Function to distribute revenues across the asset when the period matures*/
  function distributeRevenue(i) internal onlyOwner {
    
    int numberofAssets = _assetIds.current();
    int interestPerSecond = SafeMath.mul(unitPrice, (rate / 31577600)); // Secs in a year

    // Loop through assets and increment the value of each asset according to interest rate
    for (int i = 0; i < numberofAssets; i++) {
      int interest = SafeMath.mul(interestPerSecond, block.timestamp - depositTimeStamp[idToAsset[i]]);
      idToAsset[i].value = SafeMath.add(idToAsset[i].value, interest);
      emit AssetValueUpdated(idToAsset[i]);
    }

    revert("There was an error in the revenue distribution");
  }
}