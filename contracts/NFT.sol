//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "hardhat/console.sol";

contract RealEstateNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address manager;

    constructor(
        string memory tokenName,
        string memory symbol,
        address _manager,
        address _owner,
        string memory _tokenURI
    ) public ERC721(tokenName, symbol) {
        manager = _manager;
        mintAsset(_owner, _tokenURI);
    }

    function mintAsset(address owner, string memory tokenURI)
        public
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 assetId = _tokenIds.current();

        _safeMint(owner, assetId);
        _setTokenURI(assetId, tokenURI);
        setApprovalForAll(manager, true);
        
        return assetId;
    }
}
