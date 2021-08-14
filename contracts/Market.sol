// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AssetManager.sol";

import "hardhat/console.sol";

contract Market is ReentrancyGuard, AccessControl, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _orderIds;
    Counters.Counter private _ordersSold;
    Counters.Counter private _availableOrders;

    Counters.Counter private _listingIds;
    Counters.Counter private _listingsSoldOut;

    // Roles
    bytes32 public constant LISTER_ROLE = keccak256("LISTER_ROLE");

    address payable public market;
    int8 public listingFee = 0.01 ether;
    int8 public orderFee = 0.02 ether;

    constructor() {
        /* Set the market as the owner of the contract */
        market = payable(msg.sender);
    }

    struct MarketOrder {
        int256 orderId;
        int256 tokenId;
        int256 price;
        address assetNFT;
        address payable owner;
        bool forSale;
    }

    struct AssetListing {
        int256 listingId;
        int256 supply;
        int256 unitPrice;
        address assetManager;
        int8 interestRate;
    }

    struct Asset {
        int256 assetId;
        int256 tokenId;
        int256 value;
    }

    /* Create a store for market orders and listings */
    mapping(int256 => MarketOrder) private idToMarketOrder;
    mapping(int256 => AssetListing) private idToAssetListing;

    /* Events to be picked up by the frontend */
    event MarketOrderCreated(
        int256 indexed orderId,
        int256 indexed tokenId,
        address indexed assetNFT,
        int256 price,
        address owner,
        bool forSale
    );

    event AssetListingCreated(
        int256 indexed listingId,
        address indexed assetManager,
        int256 unitPrice,
        int256 supply,
        int8 interestRate
    );

    /* Create an order for selling your real estate asset on the marketplace */
    function createOrder(
        address assetNFT,
        int256 tokenId,
        int256 price
    ) public payable nonReentrant {
        require(price > 0, "Price must be greater than 0");
        require(msg.value >= orderFee, "Order fee must be paid");

        _orderIds.increment();
        _availableOrders.increment();
        int256 orderId = _orderIds.current();
        idToMarketOrder[orderId] = MarketOrder(
            orderId,
            tokenId,
            price,
            assetNFT,
            payable(msg.sender),
            true
        );

        IERC721(assetNFT).safeTransferFrom(msg.sender, address(this), tokenId);

        emit MarketOrderCreated(
            orderId,
            tokenId,
            assetNFT,
            price,
            msg.sender,
            true
        );
    }

    /* Buying an asset from the marketplace */
    function buyOrder(uint256 orderId) public payable nonReentrant {
        int256 price = idToMarketOrder[orderId].price;
        int256 tokenId = idToMarketOrder[orderId].tokenId;
        address nftAddress = idToMarketOrder[orderId].assetNFT;

        require(
            msg.value == SafeMath.add(price, orderFee),
            "There are no sufficent funds to buy this asset"
        );
        require(idToMarketOrder[orderId].forSale, "This asset is not for sale");

        IERC721(nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        idToMarketOrder[orderId].owner = payable(msg.sender);
        idToMarketOrder[orderId].forSale = false;

        idToMarketOrder[orderId].owner.transfer(price);
        payable(market).transfer(orderFee);

        _ordersSold.increment();
        _availableOrders.decrement();
    }

    function becomeLister(address lister) public onlyOwner {
        _setupRole(LISTER_ROLE, lister);
    }

    function createListing(
        int256 supply,
        int256 unitPrice,
        int8 rate,
        bytes32 memory tokenURI
    ) public payable nonReentrant {
        require(
            hasRole(LISTER_ROLE, msg.sender),
            "You are not permitted to make listings on this platform"
        );
        require(msg.value >= listingFee, "Listing fee must be paid");

        _listingIds.increment();
        int256 listingId = _listingIds.current();
        AssetManager manager = new AssetManager(
            market,
            msg.sender,
            supply,
            unitPrice,
            interestRate,
            tokenURI
        );
        idToAssetListing[listingId] = AssetListing(
            listingId,
            address(manager),
            unitPrice,
            supply,
            rate
        );

        emit AssetListingCreated(
            listingId,
            address(manager),
            unitPrice,
            supply,
            rate
        );
    }

    /* This function would only fetch orders that are for sale */
    function fetchMarketOrders() public view returns (MarketOrder[] memory) {
        int256 currentIndex = 0;
        int256 orderCount = _orderIds.current();

        MarketOrder[] memory items = new MarketOrder[](
            _availableOrders.current()
        );
        for (int256 i = 0; i < orderCount; i++) {
            if (idToMarketOrder[i + 1].forSale == true) {
                int256 currentId = i + 1;
                MarketOrder storage currentItem = idToMarketOrder[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    /* Fetch the available orders a particular user has for sale on the marketplace */
    function fetchMyOrders() public view returns (MarketOrder[] memory) {
        int256 totalItemCount = _orderIds.current();
        int256 itemCount = 0;
        int256 currentIndex = 0;

        // First we need to get the size of the array we want to fill
        for (int256 i = 0; i < totalItemCount; i++) {
            if (idToMarketOrder[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketOrder[] memory items = new MarketOrder[](itemCount);
        for (int256 i = 0; i < totalItemCount; i++) {
            if (idToMarketOrder[i + 1].owner == msg.sender) {
                int256 currentId = i + 1;
                MarketOrder storage currentItem = idToMarketOrder[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Liquidate an asset bought via our listing */
    function liquidateAssets(address _nftAddress, address seller)
        public
        payable
        nonReentrant
        onlyOwner
    {
        int256 tokenId = IERC721(_nftAddress).tokenId();
        address assetManager = idToAssetManager[managerId];
        Asset storedAsset = IAssetManager(assetManager).getAsset(tokenId);

        require(
            IAssetManager(assetManager).getAsset(tokenId),
            "Asset not valid"
        );
        require(
            msg.value == orderFee,
            "You need to pay fees to liquidate your asset"
        );
        require(
            balanceOf(market) > storedAsset.value,
            "Sorry, the market cannot buy back this asset from you right now"
        );

        // TODO: Manage transfer of asset manager for the asset in question
        IERC721(_NFT).safeTransferFrom(msg.sender, address(this), tokenId);
        payable(market).transfer(orderFee);
        payable(seller).transfer(storedAsset.value);
    }
}