// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {NFT} from "../src/NFT.sol";
import {Counters} from "../libraries/Counters";

contract CounterTest is Test {
    NFT public nft;

    event Minted(address indexed contractAddress, address indexed to, uint256 indexed tokenId, string tokenHash);


    function setUp() public {
        nft = new NFT('Test','TST');
    }

    function test_id_increments_on_emit() public {
        assertEq(nft.getTokenCounter(), 0);
        nft.mint('hash');
        assertEq(nft.getTokenCounter(), 1);
        nft.mint('hash');
        assertEq(nft.getTokenCounter(), 2);
    }

    function test_minting_does_emit() public {
        vm.expectEmit(true, true, true, true);
        emit Minted(address(nft), address(this), 1, 'hash');
        nft.mint('hash');
    }

    function test_uri_is_correct() public {
        nft.mint('hash1');
        assertEq(nft.tokenURI(1), "https://ipfs.io/ipfs/hash1");
        nft.mint('hash2');
        assertEq(nft.tokenURI(2), "https://ipfs.io/ipfs/hash2");
        nft.mint('hash3');
        assertEq(nft.tokenURI(3), "https://ipfs.io/ipfs/hash3");
    } 
}
