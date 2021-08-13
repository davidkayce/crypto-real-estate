// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./AssetManager.sol";

import "hardhat/console.sol";

contract Market is ReentrancyGuard {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private _orderIds;
  Counters.Counter private _ordersSold;
  Counters.Counter private _availableOrders;

  Counters.Counter private _listingIds;
  Counters.Counter private _listingsSoldOut;

  Counters.Counter private _managerIds;


  address payable market;
  uint256 listingFee = 0.01 ether;
  uint256 orderFee =  0.02 ether;

  constructor(){
    /* Set the market as the owner of the contract */
    market = payable(msg.sender);
  }

  struct MarketOrder {
    uint orderId;
    uint256 tokenId;
    uint256 price;
    address assetNFT;
    address payable owner;
    bool forSale;
  }

  struct AssetListing {
    uint256 listingId;
    uint256 supply;
    uint256 unitPrice;
    address assetManager;
    uint256 interestRate;
  }

  /* Create a store for market orders and listings */
  mapping(uint256 => MarketOrder) private idToMarketOrder;
  mapping(uint256 => AssetListing) private idToAssetListing;
  mapping(uint256 => address) private idToAssetManager;


  /* Events to be picked up by the frontend */
  event MarketOrderCreated (
    uint256 indexed orderId,
    uint256 indexed tokenId,
    address indexed assetNFT,
    uint256 price,
    address owner,
    bool forSale
  );

  event AssetListingCreated (
    uint256 indexed listingId,
    address indexed assetManager,
    uint256 unitPrice,
    uint256 supply,
    uint256 interestRate
  );

  /* Returns the listing fee for the market */
  function getListingFee() public view returns (uint256) {
    return listingFee;
  }
  /* Returns the transfer fee for the market */
  function getOrderFee() public view returns (uint256) {
    return orderFee;
  }

  /* Create an order for selling your real estate asset on the marketplace */
  function createOrder(address assetNFT, uint256 tokenId, uint price) public payable nonReentrant {
    require(price > 0, "Price must be greater than 0");
    require(msg.value >= orderFee, "Order fee must be paid");

    _orderIds.increment();
    _availableOrders.increment();
    uint256 orderId = _orderIds.current();
    idToMarketOrder[orderId] = MarketOrder(orderId, tokenId, price, assetNFT, payable(msg.sender), true);

    IERC721(assetNFT).safeTransferFrom(msg.sender, address(this), tokenId);

    emit MarketOrderCreated(orderId, tokenId, assetNFT, price, msg.sender, true);
  }

  /* Buying an asset from the marketplace */
  function buyOrder(uint256 orderId) public payable nonReentrant {
    uint price = idToMarketOrder[orderId].price;
    uint tokenId = idToMarketOrder[orderId].tokenId;
    address NFT = idToMarketOrder[orderId].assetNFT;

    require(msg.value == SafeMath.add(price, orderFee), "There are no sufficent funds to buy this asset");
    require(idToMarketOrder[orderId].forSale, "This asset is not for sale");

    idToMarketOrder[orderId].owner.transfer(price);
    IERC721(NFT).safeTransferFrom(address(this), msg.sender, tokenId);
    idToMarketOrder[orderId].owner = payable(msg.sender);
    idToMarketOrder[orderId].forSale = false;
    payable(market).transfer(orderFee);

    _ordersSold.increment();
    _availableOrders.decrement();
  }

  function createListing(address assetManager, uint256 tokenId, uint256 supply, uint256 unitPrice) public payable nonReentrant {
    require(msg.value >= listingFee, "Listing fee must be paid");
    // Spin off new asset manager for the listing 
  }
      
  /* This function would only fetch orders that are for sale */
  function fetchMarketOrders() public view returns (MarketOrder[] memory) {
    uint currentIndex = 0;
    uint orderCount = _orderIds.current();

    MarketOrder[] memory items = new MarketOrder[](_availableOrders.current());
    for (uint i = 0; i < orderCount; i++) {
      if (idToMarketOrder[i + 1].forSale == true) {
        uint currentId = i + 1;
        MarketOrder storage currentItem = idToMarketOrder[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    
    return items;
  }

  /* Fetch the available orders a particular user has for sale on the marketplace */
  function fetchMyOrders() public view returns (MarketOrder[] memory) {
    uint totalItemCount = _orderIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    // First we need to get the size of the array we want to fill
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketOrder[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketOrder[] memory items = new MarketOrder[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketOrder[i + 1].owner == msg.sender) {
        uint currentId = i + 1;
        MarketOrder storage currentItem = idToMarketOrder[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Liquidate an asset bought via our listing */
  function liquidateAssets(address _NFT, uint256 managerId) public payable nonReentrant {
    uint256 tokenId = IERC721(_NFT).tokenId();
    address assetManager = idToAssetManager[managerId];
    Asset storedAsset = IAssetManager(assetManager).getAsset(tokenId);

    require(IAssetManager(assetManager).getAsset(tokenId), "Asset not valid");
    require(msg.value == orderFee, "You need to pay fees to liquidate your asset");
    require(balanceOf(market) > storedAsset.value, "Sorry, the market cannot buy back this asset from you right now");

    IERC721(_NFT).safeTransferFrom(msg.sender, address(this), tokenId);
    payable(market).transfer(orderFee);
    payable(msg.sender).transfer(storedAsset.value);
  }

}