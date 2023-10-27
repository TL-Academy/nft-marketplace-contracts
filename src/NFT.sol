// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable {

    mapping (uint256 => NFTMetadata) private nfts;

    struct NFTMetadata {
        string name;
        string description;
        string image;
    }

    uint256 private _nextTokenId;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender){}

    function safeMint(address to, string memory uri, string memory name, string memory description) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        nfts[tokenId] = NFTMetadata({
            name: name,
            description: description,
            image: uri
        });
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        NFTMetadata memory nft = nfts[tokenId];
        return string(abi.encodePacked("\"name\":", nft.name, ",\"description\":", nft.description, ",\"image\":", nft.image));
    }
}