// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Errors
error Marketplace__ItemAlreadyListed(address nftContract, uint256 tokenId);
error Marketplace__NotOwner(address nftContract, uint256 tokenId, address seller);
error Marketplace__PriceZero();
error Marketplace__NotApprovedForMarketplace(address nftContract, uint256 tokenId, address marketplace);
error Marketplace__ItemNotListed(address nftContract, uint256 tokenId);
error Marketplace__NotEnoughEtherSent(uint256 itemPrice, uint256 amountSent);
error Marketplace__NothingToWithdraw();

contract Marketplace is Ownable {
    // Events
    event ItemListed(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed seller);
    event ListingCanceled(address indexed nftContract, uint256 indexed tokenId);
    event ListingUpdated(address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event ItemBought(address indexed nftContract, uint256 indexed tokenId);

    // State (storage vaiables)
    uint256 public constant COMMISSION_FEE = 0.005 ether;
    uint256 public s_totalCommission = 0;
    mapping(address => mapping(uint256 => uint256)) public s_listings; // nftContract => tokenId => price

    /**
     * @notice Construct a new Marketplace contract
     * @dev The contract is Ownable => msg.sender is the owner
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @dev Reverts if the item is already listed
     */
    modifier itemListed(address _nftContract, uint256 _tokenId) {
        uint256 price = s_listings[_nftContract][_tokenId];
        if (price > 0) revert Marketplace__ItemAlreadyListed(_nftContract, _tokenId);
        _;
    }

    /**
     * @dev Reverts if the item is not listed
     */
    modifier itemNotListed(address _nftContract, uint256 _tokenId) {
        uint256 price = s_listings[_nftContract][_tokenId];
        if (price == 0) revert Marketplace__ItemNotListed(_nftContract, _tokenId);
        _;
    }

    /**
     * @dev Reverts if the caller is not the owner of the item
     */
    modifier isOwner(address _nftContract, uint256 _tokenId) {
        IERC721 nftContract = IERC721(_nftContract);
        if (nftContract.ownerOf(_tokenId) != msg.sender) {
            revert Marketplace__NotOwner(_nftContract, _tokenId, msg.sender);
        }
        _;
    }

    /**
     * @dev
     */
    modifier isItemApprovedForMarketPlace(address _nftContract, uint256 _tokenId) {
        IERC721 nftContract = IERC721(_nftContract);
        if (nftContract.getApproved(_tokenId) != address(this)) {
            revert Marketplace__NotApprovedForMarketplace(_nftContract, _tokenId, address(this));
        }
        _;
    }

    /**
     * @notice List an item for sale
     * @param _nftContract  nft contract address
     * @param _tokenId  nft id
     * @param _price  nft price
     */
    function listItem(address _nftContract, uint256 _tokenId, uint256 _price)
        external
        isOwner(_nftContract, _tokenId)
        isItemApprovedForMarketPlace(_nftContract, _tokenId)
        itemListed(_nftContract, _tokenId)
    {
        if (_price == 0) revert Marketplace__PriceZero();
        s_listings[_nftContract][_tokenId] = _price;
        emit ItemListed(_nftContract, _tokenId, _price, msg.sender);
    }

    /**
     * @notice Buy an item
     * @param _nftContract  nft contract address
     * @param _tokenId  id of the nft to buy
     */
    function buyItem(address _nftContract, uint256 _tokenId) external payable itemNotListed(_nftContract, _tokenId) {
        uint256 price = s_listings[_nftContract][_tokenId];
        address seller = IERC721(_nftContract).ownerOf(_tokenId);

        if (msg.value < price) revert Marketplace__NotEnoughEtherSent(price, msg.value);
        delete s_listings[_nftContract][_tokenId]; // delete listing
        //Transfer NFT to buyer
        IERC721 nftContract = IERC721(_nftContract);
        nftContract.safeTransferFrom(seller, msg.sender, _tokenId);
        // Transfer funds to seller
        s_totalCommission += COMMISSION_FEE;
        payable(seller).transfer(price - COMMISSION_FEE); // send ether to seller
        emit ItemBought(_nftContract, _tokenId);
    }

    /**
     * @notice Cancel a listing
     * @param _nftContract nft contract address
     * @param _tokenId  nft id
     * @dev Listing should exist and caller should be the owner of the item
     */
    function cancelListing(address _nftContract, uint256 _tokenId)
        external
        isOwner(_nftContract, _tokenId)
        itemNotListed(_nftContract, _tokenId)
    {
        delete s_listings[_nftContract][_tokenId];
        emit ListingCanceled(_nftContract, _tokenId);
    }

    /**
     * @notice Update a listing
     * @param _nftContract nft contract address
     * @param _tokenId  nft id
     * @param _price  new nft price
     * @dev Listing should exist and caller should be the owner of the item
     */
    function updateListing(address _nftContract, uint256 _tokenId, uint256 _price)
        external
        isOwner(_nftContract, _tokenId)
        itemNotListed(_nftContract, _tokenId)
    {
        if (_price == 0) revert Marketplace__PriceZero();
        s_listings[_nftContract][_tokenId] = _price;
        emit ListingUpdated(_nftContract, _tokenId, _price);
    }

    /**
     * @notice Withdraw commission
     * @dev the owner can withdraw the accumalated through sales commission
     */
    function withdrawCommission() external onlyOwner {
        if (s_totalCommission == 0) revert Marketplace__NothingToWithdraw();
        uint256 commission = s_totalCommission;
        s_totalCommission = 0;
        payable(msg.sender).transfer(commission);
    }

    /**
     * @dev getter of easier access to listing
     */
    function getListing(address _nftContract, uint256 _tokenId) external view returns (uint256, address) {
        uint256 price = s_listings[_nftContract][_tokenId];
        IERC721 nftContract = IERC721(_nftContract);
        return (price, nftContract.ownerOf(_tokenId));
    }
}
