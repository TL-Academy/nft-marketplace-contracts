// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./NFT.sol";

contract Marketplace {

    event NFTListed(address indexed _listedBy, address indexed _collection, uint256 _id);
    event NFTDelisted(address indexed _deletedBy, address indexed _collection, uint256 _id);
    event NFTUpdated(address indexed _updatedBy, address indexed _collection, uint256 _id);
    event NFTTransfered(
        address indexed _transferedFrom, 
        address indexed _transferedTo, 
        address _collection, 
        uint256 _id
    );

    // contract -> (id -> price)
    mapping (address =>  mapping(uint256 => uint256)) private NFTPrices;

    modifier isNFTOwner(address _collection, uint256 _id) {
        require(NFT(_collection).ownerOf(_id) == msg.sender, "Not the owner!");
        _;
    }    

    // listed true -> revert if already listed. false -> revert if not listed
    modifier alreadyListed(address _collection, uint256 _id, bool listed) {
        if (listed && NFTPrices[_collection][_id] != 0) revert("Already listed");
        if (!listed && NFTPrices[_collection][_id] == 0) revert("Item not listed");
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
        require(_price!=0, "Price should be more than 0");
        NFTPrices[_collection][_id] = _price;
        emit NFTListed(msg.sender, _collection, _id);
    } 


    function delist(
        address _collection, 
        uint256 _id
    ) 
    public 
    isNFTOwner(_collection, _id)
    alreadyListed(_collection, _id, false)
    {
        delete NFTPrices[_collection][_id];
        emit NFTDelisted(msg.sender, _collection, _id);
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
        require(NFTPrices[_collection][_id] < _newPrice);
        NFTPrices[_collection][_id] = _newPrice;
        emit NFTUpdated(msg.sender, _collection, _id);        
    }


    function buyNFT(address _collection, uint256 _id) payable public {
        NFT currentCollection = NFT(_collection);
        uint256 _price = NFTPrices[_collection][_id];
        require(currentCollection.getApproved(_id) == address(this), "Marketplace is not approved");
        require(msg.value == _price, "Invalid price");
        address currentOwner = currentCollection.ownerOf(_id);
        
        currentCollection.safeTransferFrom(
            currentOwner, 
            msg.sender, 
            _id
        );

        emit NFTTransfered(currentOwner, msg.sender, _collection, _id);
        (bool succes,) = currentOwner.call{value: _price}("");
        require(succes, "Error paying old owner");
    }
}