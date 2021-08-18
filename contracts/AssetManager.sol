// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAssetManager.sol";
import "./NFT.sol";

import "hardhat/console.sol";

// TODO: create a buyAsset function to be called when a seller buys an order;

contract AssetManager is ReentrancyGuard, IAssetManager, Ownable {
  /* The  asset mamager is responsible for setting up the assets, updating value and liquidating assets */
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private _assetIds;
  Counters.Counter private _assetsSold;

  /* Events to be picked up by the frontend */
  address payable public market;
  address payable public issuer;

  uint256 public assetSupply;
  uint256 public unitPrice;
  uint256 public unitsSold;
  int8 public rate;

  constructor(
    address _market,
    address _issuer,
    uint256 _maxSupply,
    uint256 _unitPrice,
    int8 _rate
  ) {
    market = payable(_market);
    issuer = payable(_issuer);
    assetSupply = _maxSupply;
    unitPrice = _unitPrice;
    rate = _rate;
  }

  struct Asset {
    uint256 assetId;
    uint256 tokenId;
    uint256 value;
    address assetAddress;
    uint256 units;
  }

  event AssetCreated(uint256 indexed assetId, uint256 indexed tokenId, uint256 value, address indexed assetAddress);

  event AssetValueUpdated(Asset asset);

  event TransferMade(address indexed sender, uint256 value);

  mapping(uint256 => Asset) private idToAsset;
  mapping(address => Asset) private nftAddressToAsset;
  mapping(uint256 => uint256) private depositTimeStamp;
  mapping(uint256 => uint256) private interestPaid;

  /* Revenue on  asset yet to be distributed */
  uint256 internal accumulated = 0;

  /* Function to fetch  a created asset */
  function getAsset(address assetAddress) public view returns (Asset memory) {
    require(nftAddressToAsset[assetAddress], "This asset does not exist");
    return nftAddressToAsset[assetAddress];
  }

  function isStakeholder(uint256 id) public view returns (bool, Asset memory) {
    if (idToAsset[id]) return (true, idToAsset[id]);
    return (false, Asset(0, 0, 0));
  }

  function isSoldOut() public view returns (bool) {
    return (unitsSold >= assetSupply);
  }

  /* Function to mint the NFT for the real esate asset */
  /* This is only called when the original listing wants to be bought */
  function createAsset(uint256 units, address assetOwner) public payable override nonReentrant returns (address) {
    int8 mintFee = 0.01 ether;
    uint256 totalPrice = SafeMath.mul(units, unitPrice) + mintFee;

    require(assetSupply >= SafeMath.add(units, unitsSold), "Total supply of assets have been exceeded, you cannot purchase anymore of this asset");
    require(msg.value == totalPrice, "Please pay the asking price with fees");

    _assetIds.increment();
    unitsSold += units;
    uint256 assetId = _assetIds.current();
    (uint256 tokenId, address nftAddress) = new RealEstateNFT(assetId, assetSupply, unitPrice, rate, assetOwner);

    idToAsset[assetId] = Asset(assetId, tokenId, SafeMath.mul(units, unitPrice), nftAddress, units);
    nftAddressToAsset[nftAddress] = Asset(assetId, tokenId, SafeMath.mul(units, unitPrice), nftAddress, units);
    // This is being flagged because we are advised not to write time dependent logic
    depositTimeStamp[idToAsset[assetId]] = block.timestamp;

    payable(issuer).transfer(SafeMath.mul(units, unitPrice));
    payable(market).transfer(mintFee);

    emit AssetCreated(assetId, tokenId, assetSupply, nftAddress);

    return nftAddress;
  }

  /* This code is run anytime money is sent to this address */
  receive() external payable {
    require(msg.value > 0, "Non-zero revenue please");
    accumulated += msg.value;
    payable(market).transfer(msg.value);
    emit TransferMade(msg.sender, msg.value);
  }

  // Integrate chainlink API here to automatically
  // distribute revenue to the assets

  /* Function to distribute revenues across the asset when the period matures*/
  function distributeRevenue() internal onlyOwner {
    uint256 numberofAssets = _assetIds.current();
    uint256 interestPerSecond = SafeMath.mul(unitPrice, (rate / 31577600)); // Secs in a year

    // Loop through assets and increment the value of each asset according to interest rate
    for (uint256 i = 0; i < numberofAssets; i++) {
      uint256 interest = SafeMath.mul(interestPerSecond, block.timestamp - depositTimeStamp[idToAsset[i]]);
      idToAsset[i].value = SafeMath.add(idToAsset[i].value, interest);
      emit AssetValueUpdated(idToAsset[i]);
    }

    revert("There was an error in the revenue distribution");
  }
}
