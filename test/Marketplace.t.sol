// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import "../src/Marketplace.sol";
import {NFT} from "../src/NFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract MarketplaceTest is Test {
    NFT public nft;
    Marketplace public marketplace;

    address otherAddr = makeAddr("otherAddr");

    event NFTListed(
        address indexed collection,
        uint256 indexed price,
        uint256 indexed id
    );
    event ListingCanceled(address indexed collection, uint256 indexed id);
    event ListingUpdated(
        address indexed collection,
        uint256 indexed newPrice,
        uint256 indexed id
    );
    event NFTTransfered(
        address indexed transferedTo,
        address indexed collection,
        uint256 indexed id
    );

    function setUp() public {
        nft = new NFT("Test", "TST");
        marketplace = new Marketplace();

        nft.mint("hash");
        nft.mint("hash2");
    }

    function testList() public {
        vm.expectEmit(true, true, true, true);
        emit NFTListed(address(nft), 5000, 1);
        marketplace.list(address(nft), 1, 5000);
    }

    function testListZeroPrice() public {
        vm.expectRevert(Marketplace__priceIsZero.selector);
        marketplace.list(address(nft), 2, 0);
    }

    function testListNotOwner() public {
        vm.expectRevert(Marketplace__notOwner.selector);
        vm.prank(otherAddr);
        marketplace.list(address(nft), 2, 1000);
    }

    function testAlreadyListed() public {
        marketplace.list(address(nft), 1, 5000);

        vm.expectRevert(Marketplace__itemAlreadyListed.selector);
        marketplace.list(address(nft), 1, 5000);
    }

    function testDelist() public {
        marketplace.list(address(nft), 1, 5000);

        vm.expectEmit(true, true, true, true);
        emit ListingCanceled(address(nft), 1);
        marketplace.delist(address(nft), 1);
    }

    function testDelistNotOwner() public {
        marketplace.list(address(nft), 1, 5000);

        vm.expectRevert(Marketplace__notOwner.selector);
        vm.prank(otherAddr);
        marketplace.delist(address(nft), 1);
    }

    function testDelistNFTNotListed() public {
        vm.expectRevert(Marketplace__itemNotListed.selector);
        marketplace.delist(address(nft), 1);
    }

    function testUpdatePrice() public {
        marketplace.list(address(nft), 1, 5000);

        vm.expectEmit(true, true, true, true);
        emit ListingUpdated(address(nft), 5001, 1);
        marketplace.updatePrice(address(nft), 1, 5001);
    }

    function testUpdatePriceWithLowerPrice() public {
        marketplace.list(address(nft), 1, 5000);

        vm.expectRevert(Marketplace__newPriceNotHigher.selector);
        marketplace.updatePrice(address(nft), 1, 1000);
    }

    function testUpdatePriceNotOwner() public {
        marketplace.list(address(nft), 1, 5000);

        vm.expectRevert(Marketplace__notOwner.selector);
        vm.prank(otherAddr);
        marketplace.updatePrice(address(nft), 1, 5001);
    }

    function testUpdatePriceNotListed() public {
        vm.expectRevert(Marketplace__itemNotListed.selector);
        marketplace.updatePrice(address(nft), 1, 5000);
    }

    function testBuyNFT() public {
        vm.prank(otherAddr);
        nft.mint("test");
        vm.prank(otherAddr);
        nft.approve(address(marketplace), 3);
        vm.prank(otherAddr);
        marketplace.list(address(nft), 3, 5000);

        vm.prank(otherAddr);
        vm.deal(otherAddr, 1 ether);
        vm.expectEmit(true, true, true, true);
        emit NFTTransfered(otherAddr, address(nft), 3);
        marketplace.buyNFT{value: 5000}(address(nft), 3);
    }

    function testBuyNFTNotApprovedMP() public {
        marketplace.list(address(nft), 1, 5000);

        vm.expectRevert(Marketplace__marketplaceIsNotApproved.selector);
        vm.prank(otherAddr);
        vm.deal(otherAddr, 1 ether);
        marketplace.buyNFT{value: 5000}(address(nft), 1);
    }

    function testBuyNFTIncorectProceProvider() public {
        vm.prank(otherAddr);
        nft.mint("test");
        vm.prank(otherAddr);
        nft.approve(address(marketplace), 3);
        vm.prank(otherAddr);
        marketplace.list(address(nft), 3, 5000);

        vm.expectRevert(Marketplace__incorectPriceProvided.selector);
        vm.prank(otherAddr);
        vm.deal(otherAddr, 1 ether);
        marketplace.buyNFT{value: 5001}(address(nft), 3);
    }

    // TODO: Not working - needs fix
    function testBuyNFTCouldntPayOldOwner() public {
        CantReceive receiver = new CantReceive();
        vm.prank(otherAddr);
        nft.mint("test");
        vm.prank(otherAddr);
        nft.approve(address(marketplace), 3);
        vm.prank(otherAddr);
        marketplace.list(address(nft), 3, 5000);
        vm.prank(otherAddr);
        vm.deal(otherAddr, 1 ether);
        (bool success,) = address(receiver).call{value: 10000}("fallback");
        if (success) {
            receiver.buyNFT{value: 5000}(address(marketplace), address(nft), 3);
            receiver.approve(address(marketplace), address(nft), 3);
            bytes4 selector = bytes4(
                keccak256("Marketplace__couldntPayOldOwner()")
            );
            vm.expectRevert(abi.encodeWithSelector(selector));
            vm.prank(otherAddr);
            marketplace.buyNFT{value: 5000}(address(nft), 3);
        }
    }
}

contract CantReceive is IERC721Receiver {
    function buyNFT(
        address _marketplace,
        address _collection,
        uint256 _id
    ) public payable {
        Marketplace(_marketplace).buyNFT{value: msg.value}(_collection, _id);
    }

    function approve(address _marketplace, address _nft, uint256 _id) public {
        NFT(_nft).approve(_marketplace, _id);
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {}

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
