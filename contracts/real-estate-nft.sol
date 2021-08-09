//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Real Estate NFT
 * @author David Kayce
 * @notice Implements a real estate NFT contract with revenue distribution.
 */

contract RealEstateNFT is ERC721 {
    /**
     * @notice We need to know all the stakeholders in the system.
     */
    address public issuer; // originator of the asset (normally the company)

    // Transaction properties
    address public txFeeToken;
    uint256 public txFeeAmount;
    uint256 public mintFeeAmount;
    uint256 public tokenValue;
    uint256 internal accumulated; // total amount of undistributed revenue
    mapping(address => bool) public excludedList; // list of addresses that are excluded from paying fees

    /**
     * @notice The constructor for the Real Estate NFT. This contract represents 
     a unique real estate portfolio and each NFT minted is a share.
     * @param _issuer The address to receive all tokens on construction.
     * @param _supply The amount of tokens to mint on construction.
     * @param _txFeeToken The token used for transaction fees.
     * @param _txFeeAmount The transaction fee for NFT transfer.
     */
    constructor(address _issuer, uint256 _supply, uint256 _interest, string memory tokenURI) public ERC721("ProperTee", "PRPT") {
        issuer = _issuer;
        supply = _supply;
        txFeeToken = _txFeeToken;
        tokenValue = _value;
        txFeeAmount = 0.1 * 10**18;
        excludedList[_issuer] = true;
    }

    function mintHouseAsset(
        uint256 seed,
        uint256 _units,
        address _txFeeToken,
        uint256 _value
    ) returns (bytes32) {
        require(supply > _units, "Total supply of assets  have been exceeded, you cannot purchase anymore of this asset");
        // TODO: Handle hashing seed with
        _safeMint(msg.sender, tokenId);
    }

    // Transfers and implementing transfer fee
    function setExcluded(address excluded, bool status) external {
        require(msg.sender == issuer, "You are not approved to update fees exclusion");
        excludedList[excluded] = status;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        if (excludedList[from] == false) {
            _payTxFee(from);
        }
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (excludedList[from] == false) {
            _payTxFee(from);
        }
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        if (excludedList[from] == false) {
            _payTxFee(from);
        }
        _safeTransfer(from, to, tokenId, _data);
    }

    function _payTxFee(address from, string memory type) internal {
        IERC20 token = IERC20(txFeeToken);
        token.safeTransferFrom(from, artist, txFeeAmount);
    }

    // Marketplace
    function payout(
        uint256 tokenId,
        uint256 amount,
        address issuer,
        address receipient
    ) public {}

    function updateValue(uint256 tokenId, uint256 interest) public {}
}
