pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Real Estate NFT
 * @author David Kayce
 * @notice Implements a real estate NFT contract with revenue distribution.
 */

contract RealEstateNFT is ERC721 {
    using SafeMath for uint256;

    /**
     * @notice We need to know all the stakeholders in the system.
     */
    address public issuer; // originator of the asset (normally the company)
    address[] internal stakeholders; // all the people who have a stake in the asset

    // Transaction properties
    address public txFeeToken;
    uint256 public txFeeAmount;
    uint256 internal accumulated; // total amount of undistributed revenue
    mapping(address => bool) public excludedList;
    mapping(address => uint256) internal revenues; // The accumulated revenue for each stakeholder.

    /**
     * @notice The constructor for the Real Estate NFT. This contract represents 
     a unique real estate portfolio and each NFT minted is a share.
     * @param _issuer The address to receive all tokens on construction.
     * @param _supply The amount of tokens to mint on construction.
     * @param _txFeeToken The token used for transaction fees.
     * @param _txFeeAmount The transaction fee for NFT transfer.
     */
    constructor(
        address _issuer,
        uint256 _supply,
        address _txFeeToken,
        uint256 _txFeeAmount
    ) ERC721("My NFT", "ABC") {
      issuer = _issuer;
      txFeeToken = _txFeeToken;
      txFeeAmount = _txFeeAmount;
      excludedList[_artist] = true;
      _mint(_owner, _supply);
    }
}
