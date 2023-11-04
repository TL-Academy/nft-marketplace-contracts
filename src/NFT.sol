// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Counters} from "./libraries/Counters.sol";

contract NFT is ERC721URIStorage {
    event Minted(address indexed contractAddress, address indexed to, uint256 indexed tokenId, string tokenHash);

    using Counters for Counters.Counter;

    Counters.Counter private s_tokenIds;
    mapping(uint256 => string) public s_tokenHashes; //id => hash

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    /**
     * @notice Mint a new token
     * @param _tokenHash metadata uri (ipfs CID hash)
     */
    function mint(string memory _tokenHash) public returns (uint256) {
        s_tokenIds.increment();
        uint256 newTokenId = s_tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenHash);
        // @note this is the event that we will listen for in the fe
        emit Minted(address(this), msg.sender, newTokenId, _tokenHash);
        return newTokenId;
    }

    /**
     * @notice Here we override the baseUri function to construct our tokenUri directly in the contract
     * @dev this function is called in the tokenURI function which is inherited from the ERC721URIStorage
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenIds.current();
    }
}
