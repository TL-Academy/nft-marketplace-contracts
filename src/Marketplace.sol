// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./NFT.sol";

error Marketplace__notOwner();
error Marketplace__itemAlreadyListed();
error Marketplace__itemNotListed();
error Marketplace__priceIsZero();
error Marketplace__newPriceNotHigher();
error Marketplace__couldntPayOldOwner();
error Marketplace__marketplaceIsNotApproved();
error Marketplace__incorectPriceProvided();

contract Marketplace {

    event NFTListed(address indexed collection, uint256 indexed price, uint256 indexed id);
    event ListingCanceled(address indexed collection, uint256 indexed id);
    event ListingUpdated(address indexed collection, uint256 indexed newPrice, uint256 indexed id);
    event NFTTransfered(address indexed transferedTo, address indexed collection, uint256 indexed id);

    // contract -> (id -> price)
    mapping (address =>  mapping(uint256 => uint256)) private s_NFTPrices;

    modifier isNFTOwner(address _collection, uint256 _id) {
        if (NFT(_collection).ownerOf(_id) != msg.sender) revert Marketplace__notOwner();
        _;
    }    

    // listed true -> revert if already listed. false -> revert if not listed
    modifier alreadyListed(address _collection, uint256 _id, bool listed) {
        if (listed && s_NFTPrices[_collection][_id] != 0) revert Marketplace__itemAlreadyListed();
        if (!listed && s_NFTPrices[_collection][_id] == 0) revert Marketplace__itemNotListed();
        _;
    }


    function list(
        address _collection, 
        uint256 _id, 
        uint256 _price
    ) 
    public 
    isNFTOwner(_collection, _id)
    alreadyListed(_collection, _id, true)
    {
        if(_price==0) revert Marketplace__priceIsZero();
        s_NFTPrices[_collection][_id] = _price;
        emit NFTListed(_collection, _price, _id);
    } 


    function delist(
        address _collection, 
        uint256 _id
    ) 
    public 
    isNFTOwner(_collection, _id)
    alreadyListed(_collection, _id, false)
    {
        delete s_NFTPrices[_collection][_id];
        emit ListingCanceled(_collection, _id);
    }


    function updatePrice(
        address _collection, 
        uint256 _id,
        uint256 _newPrice
    )
    public
    isNFTOwner(_collection, _id) 
    alreadyListed(_collection, _id, false)
    {
        if(s_NFTPrices[_collection][_id] >= _newPrice) revert Marketplace__newPriceNotHigher();
        s_NFTPrices[_collection][_id] = _newPrice;
        emit ListingUpdated(_collection, _newPrice, _id);        
    }


    function buyNFT(address _collection, uint256 _id) payable public {
        NFT currentCollection = NFT(_collection);
        uint256 _price = s_NFTPrices[_collection][_id];
        if (currentCollection.getApproved(_id) != address(this)) revert Marketplace__marketplaceIsNotApproved();
        if (msg.value != _price) revert Marketplace__incorectPriceProvided();
        address currentOwner = currentCollection.ownerOf(_id);
        
        currentCollection.safeTransferFrom(
            currentOwner, 
            msg.sender, 
            _id
        );

        (bool succes,) = currentOwner.call{value: _price}("");
        if(!succes) revert Marketplace__couldntPayOldOwner();
        emit NFTTransfered(currentOwner, msg.sender, _collection, _id);
    }
}