// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./NFT.sol";

contract Marketplace {

    event NFTListed(address indexed listedBy, address indexed collection, uint256 indexed price, uint256 id);
    event ListingCanceled(address indexed collection, uint256 id);
    event ListingUpdated(address indexed collection, uint256 indexed newPrice, uint256 id);
    event NFTTransfered(
        address indexed transferedFrom, 
        address indexed transferedTo, 
        address collection, 
        uint256 id
    );

    // contract -> (id -> price)
    mapping (address =>  mapping(uint256 => uint256)) private s_NFTPrices;

    error notOwner();
    error itemAlreadyListed();
    error itemNotListed();
    error priceIsZero();
    error newPriceNotHigher();
    error couldntPayOldOwner();
    error marketplaceIsNotApproved();
    error incorectPriceProvided();

    modifier isNFTOwner(address _collection, uint256 _id) {
        if (NFT(_collection).ownerOf(_id) != msg.sender) revert notOwner();
        _;
    }    

    // listed true -> revert if already listed. false -> revert if not listed
    modifier alreadyListed(address _collection, uint256 _id, bool listed) {
        if (listed && s_NFTPrices[_collection][_id] != 0) revert itemAlreadyListed();
        if (!listed && s_NFTPrices[_collection][_id] == 0) revert itemNotListed();
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
        if(_price==0) revert priceIsZero();
        s_NFTPrices[_collection][_id] = _price;
        emit NFTListed(msg.sender, _collection, _price, _id);
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
        if(s_NFTPrices[_collection][_id] >= _newPrice) revert newPriceNotHigher();
        s_NFTPrices[_collection][_id] = _newPrice;
        emit ListingUpdated(_collection, _newPrice, _id);        
    }


    function buyNFT(address _collection, uint256 _id) payable public {
        NFT currentCollection = NFT(_collection);
        uint256 _price = s_NFTPrices[_collection][_id];
        if (currentCollection.getApproved(_id) != address(this)) revert marketplaceIsNotApproved();
        if (msg.value != _price) revert incorectPriceProvided();
        address currentOwner = currentCollection.ownerOf(_id);
        
        currentCollection.safeTransferFrom(
            currentOwner, 
            msg.sender, 
            _id
        );

        emit NFTTransfered(currentOwner, msg.sender, _collection, _id);
        (bool succes,) = currentOwner.call{value: _price}("");
        if(!succes) revert couldntPayOldOwner();
    }
}